#include "builtin.h"
#include "json-writer.h"
#include "parse-options.h"
#include "refs.h"

enum output_format {
	FORMAT_JSON,
	FORMAT_NULL_TERMINATED,
};

enum repo_info_category {
	CATEGORY_REFERENCES = 1 << 0,
};

enum repo_info_references_field {
	FIELD_REFERENCES_FORMAT = 1 << 0,
};

struct repo_info_field {
	enum repo_info_category category;
	union {
		enum repo_info_references_field references;
	} u;
};

struct repo_info {
	struct repository *repo;
	enum output_format format;
	size_t fields_nr;
	struct repo_info_field *fields;
};

static void repo_info_init(struct repo_info *repo_info,
			   struct repository *repo,
			   const char *format,
			   int argc, const char **argv)
{
	repo_info->repo = repo;

	if (!format || !strcmp(format, "json"))
		repo_info->format = FORMAT_JSON;
	else if (!strcmp(format, "null-terminated"))
		repo_info->format = FORMAT_NULL_TERMINATED;
	else
		die("invalid format %s", format);

	repo_info->fields_nr = argc;
	ALLOC_ARRAY(repo_info->fields, argc);

	for (int i = 0; i < argc; i++) {
		const char *arg = argv[i];
		struct repo_info_field *field = repo_info->fields + i;
		if (!strcmp(arg, "references.format")) {
			field->category = CATEGORY_REFERENCES;
			field->u.references = FIELD_REFERENCES_FORMAT;
		} else {
			die("invalid field '%s'", arg);
		}
	}
}

static void repo_info_release(struct repo_info *repo_info)
{
	free(repo_info->fields);
}

static void append_null_terminated_field(struct strbuf *buf,
					 struct repo_info *repo_info,
					 struct repo_info_field *field)
{
	struct repository *repo = repo_info->repo;

	switch (field->category) {
	case CATEGORY_REFERENCES:
		strbuf_addstr(buf, "references.");
		switch (field->u.references) {
		case FIELD_REFERENCES_FORMAT:
			strbuf_addstr(buf, "format\n");
			strbuf_addstr(buf, ref_storage_format_to_name(
						   repo->ref_storage_format));
			break;
		}
		break;
	}

	strbuf_addch(buf, '\0');
}

static void repo_info_print_null_terminated(struct repo_info *repo_info)
{
	struct strbuf buf;

	strbuf_init(&buf, 256);

	for (size_t i = 0; i < repo_info->fields_nr; i++) {
		struct repo_info_field *field = &repo_info->fields[i];
		append_null_terminated_field(&buf, repo_info, field);
	}

	fwrite(buf.buf, 1, buf.len, stdout);
	strbuf_release(&buf);
}

static void repo_info_print_json(struct repo_info *repo_info)
{
	struct json_writer jw;
	unsigned int categories = 0;
	unsigned int references_fields = 0;
	struct repository *repo = repo_info->repo;

	for (size_t i = 0; i < repo_info->fields_nr; i++) {
		struct repo_info_field *field = repo_info->fields + i;
		categories |= field->category;
		switch (field->category) {
		case CATEGORY_REFERENCES:
			references_fields |= field->u.references;
			break;
		}
	}

	jw_init(&jw);

	jw_object_begin(&jw, 1);
	if (categories & CATEGORY_REFERENCES) {
		jw_object_inline_begin_object(&jw, "references");
		if (references_fields & FIELD_REFERENCES_FORMAT) {
			const char *format_name = ref_storage_format_to_name(
				repo->ref_storage_format);
			jw_object_string(&jw, "format", format_name);
		}
		jw_end(&jw);
	}
	jw_end(&jw);

	puts(jw.json.buf);
	jw_release(&jw);
}

static void repo_info_print(struct repo_info *repo_info)
{
	switch (repo_info->format) {
	case FORMAT_JSON:
		repo_info_print_json(repo_info);
		break;
	case FORMAT_NULL_TERMINATED:
		repo_info_print_null_terminated(repo_info);
		break;
	default:
		BUG("%d: not a valid repo-info format", repo_info->format);
	}
}

int cmd_repo_info(int argc,
		  const char **argv,
		  const char *prefix,
		  struct repository *repo)
{
	const char *const repo_info_usage[] = {
		"git repo-info [--format <format>] [<field>...]",
		NULL
	};
	struct repo_info repo_info;
	const char *format = NULL;
	struct option options[] = {
		OPT_STRING(0, "format", &format, N_("format"),
			   N_("output format")),
		OPT_END()
	};

	argc = parse_options(argc, argv, prefix, options, repo_info_usage,
			     0);
	repo_info_init(&repo_info, repo, format, argc, argv);
	repo_info_print(&repo_info);
	repo_info_release(&repo_info);

	return 0;
}
