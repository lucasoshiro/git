#include "builtin.h"
#include "hash.h"
#include "json-writer.h"
#include "parse-options.h"
#include "refs.h"

enum output_format {
	FORMAT_PLAINTEXT,
	FORMAT_JSON
};

struct repo_info_json_schema {
	struct {
		int use;
		int format;
	} objects;
	struct {
		int use;
		int format;
	} references;
};

struct repo_info {
	struct repository *repo;
	enum output_format format;
	union {
		struct repo_info_json_schema json;
		struct strbuf plaintext;
	} body;
};

static void repo_info_init(struct repo_info *repo_info,
			   struct repository *repo,
			   char *format,
			   int argc,
			   const char **argv
			   ) {
	repo_info->repo = repo;

	if (format == NULL || !strcmp(format, "json")) {
		repo_info->format = FORMAT_JSON;
		memset(&repo_info->body.json, 0, sizeof(repo_info->body.json));
	}
	else if (!strcmp(format, "plaintext")) {
		repo_info->format = FORMAT_PLAINTEXT;
		strbuf_init(&repo_info->body.plaintext, 32);
	}
	else {
		die("invalid format %s", format);
	}

	do {
		const char *arg = *argv;

		if (argc == 0 || !strcmp(arg, "objects.format")) {
			switch (repo_info->format) {
			case FORMAT_PLAINTEXT:
				strbuf_addstr(&repo_info->body.plaintext,
					      repo->hash_algo->name);
				strbuf_addch(&repo_info->body.plaintext, '\n');
				break;
			case FORMAT_JSON:
				repo_info->body.json.objects.use = 1;
				repo_info->body.json.objects.format = 1;
				break;
			}
			if (argc != 0) goto next;
		}

		if (argc == 0 || !strcmp(arg, "references.format")) {
			switch (repo_info->format) {
			case FORMAT_PLAINTEXT:
				strbuf_addstr(&repo_info->body.plaintext,
					      ref_storage_format_to_name(repo->ref_storage_format)
					      );
				strbuf_addch(&repo_info->body.plaintext, '\n');
				break;
			case FORMAT_JSON:
				repo_info->body.json.references.use = 1;
				repo_info->body.json.references.format = 1;
				break;
			}
			if (argc != 0) goto next;
		}

		if (argc != 0) die("invalid field %s", arg);

	next:
		argc--;
		argv++;
	} while (argc >= 1);
}

static void repo_info_release(struct repo_info *repo_info) {
	if (repo_info->format == FORMAT_PLAINTEXT) {
		strbuf_release(&repo_info->body.plaintext);
	}
}

static void repo_info_print_json(struct repository *repo,
				 struct repo_info_json_schema *schema)
{
	struct json_writer jw;

	jw_init(&jw);

	jw_object_begin(&jw, 1);
	if (schema->objects.use) {
		jw_object_inline_begin_object(&jw, "objects");
		if (schema->objects.format) {
			jw_object_string(&jw, "format",
					 repo->hash_algo->name);
		}
		jw_end(&jw);
	}
	if (schema->references.use) {
		jw_object_inline_begin_object(&jw, "references");
		if (schema->references.format) {
			jw_object_string(&jw, "format", ref_storage_format_to_name(repo->ref_storage_format));
		}
		jw_end(&jw);
	}
	jw_end(&jw);

	puts(jw.json.buf);
	jw_release(&jw);
}

static void repo_info_print(struct repo_info *repo_info)
{
	enum output_format format = repo_info->format;
	struct repository *repo = repo_info->repo;

	switch (format) {
	case FORMAT_PLAINTEXT:
		printf("%s", repo_info->body.plaintext.buf);
		break;

	case FORMAT_JSON:
		repo_info_print_json(repo, &repo_info->body.json);
		break;
	}
}

int cmd_repo_info(
	int argc,
	const char **argv,
	const char *prefix,
	struct repository *repo
	)
{
	const char *const repo_info_usage[] = {
		"git repo-info",
		NULL
	};
	struct repo_info repo_info;
	char *format = NULL;
	struct option options[] = {
		OPT_STRING(0,
			     "format",
			     &format,
			     N_("format"),
			     N_("format")),
		OPT_END()
	};

	argc = parse_options(argc, argv, prefix, options, repo_info_usage, PARSE_OPT_KEEP_UNKNOWN_OPT);

	repo_info_init(&repo_info, repo, format, argc, argv);
	repo_info_print(&repo_info);
	repo_info_release(&repo_info);

	return 0;
}
