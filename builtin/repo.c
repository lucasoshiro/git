#define USE_THE_REPOSITORY_VARIABLE

#include "builtin.h"
#include "environment.h"
#include "parse-options.h"
#include "quote.h"
#include "refs.h"
#include "strbuf.h"
#include "shallow.h"

static const char *const repo_usage[] = {
	"git repo info [<key>...]",
	NULL
};

typedef int get_value_fn(struct repository *repo, struct strbuf *buf);

struct field {
	const char *key;
	get_value_fn *get_value;
};

static int get_layout_bare(struct repository *repo UNUSED, struct strbuf *buf)
{
	strbuf_addstr(buf, is_bare_repository() ? "true" : "false");
	return 0;
}

static int get_layout_shallow(struct repository *repo, struct strbuf *buf)
{
	strbuf_addstr(buf,
		      is_repository_shallow(repo) ? "true" : "false");
	return 0;
}

static int get_references_format(struct repository *repo, struct strbuf *buf)
{
	strbuf_addstr(buf,
		      ref_storage_format_to_name(repo->ref_storage_format));
	return 0;
}

/* repo_info_fields keys should be in lexicographical order */
static const struct field repo_info_fields[] = {
	{ "layout.bare", get_layout_bare },
	{ "layout.shallow", get_layout_shallow },
	{ "references.format", get_references_format },
};

static int repo_info_fields_cmp(const void *va, const void *vb)
{
	const struct field *a = va;
	const struct field *b = vb;

	return strcmp(a->key, b->key);
}

static get_value_fn *get_value_fn_for_key(const char *key)
{
	const struct field search_key = { key, NULL };
	const struct field *found = bsearch(&search_key, repo_info_fields,
					    ARRAY_SIZE(repo_info_fields),
					    sizeof(*found),
					    repo_info_fields_cmp);
	return found ? found->get_value : NULL;
}

static int qsort_strcmp(const void *va, const void *vb)
{
	const char *a = *(const char **)va;
	const char *b = *(const char **)vb;

	return strcmp(a, b);
}

static int print_fields(int argc, const char **argv, struct repository *repo)
{
	int ret = 0;
	const char *last = "";
	struct strbuf valbuf = STRBUF_INIT;
	struct strbuf quotbuf = STRBUF_INIT;

	QSORT(argv, argc, qsort_strcmp);

	for (int i = 0; i < argc; i++) {
		get_value_fn *get_value;
		const char *key = argv[i];

		strbuf_reset(&valbuf);
		strbuf_reset(&quotbuf);

		if (!strcmp(key, last))
			continue;

		last = key;
		get_value = get_value_fn_for_key(key);

		if (!get_value) {
			ret = error(_("key '%s' not found"), key);
			continue;
		}

		get_value(repo, &valbuf);
		quote_c_style(valbuf.buf, &quotbuf, NULL, 0);
		printf("%s=%s\n", key, quotbuf.buf);
	}

	strbuf_release(&valbuf);
	strbuf_release(&quotbuf);
	return ret;
}

static int repo_info(int argc, const char **argv, const char *prefix UNUSED,
		     struct repository *repo)
{
	return print_fields(argc - 1, argv + 1, repo);
}

int cmd_repo(int argc, const char **argv, const char *prefix,
	     struct repository *repo)
{
	parse_opt_subcommand_fn *fn = NULL;
	struct option options[] = {
		OPT_SUBCOMMAND("info", &fn, repo_info),
		OPT_END()
	};

	argc = parse_options(argc, argv, prefix, options, repo_usage, 0);

	return fn(argc, argv, prefix, repo);
}
