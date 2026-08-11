package aeolus.application;

import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.files.StaticFile;
import dobby.files.service.IStaticFileService;
import dobby.filter.Filter;
import dobby.filter.FilterType;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;

@RegisterFor(SPAFilter.class)
public class SPAFilter implements Filter {
    private final IStaticFileService staticFileService;

    @Inject
    public SPAFilter(IStaticFileService staticFileService) {
        this.staticFileService = staticFileService;
    }

    @Override
    public String getName() {
        return "aeolus-spa-filter";
    }

    @Override
    public FilterType getType() {
        return FilterType.POST;
    }

    @Override
    public int getOrder() {
        return 100;
    }

    @Override
    public boolean run(HttpContext ctx) {
        if (ctx.getRequest().getPath().startsWith("/landing")) {
            sendElmApp(ctx);
            return true;
        }

        if (ctx.getResponse().getCode() != ResponseCodes.NOT_FOUND) {
            return true;
        }

        if (ctx.getRequest().getPath().startsWith("/rest/")) {
            return true;
        }

        final String contentType = ctx.getResponse().getHeader("Content-Type");
        if (contentType == null || (!contentType.contains("text/html") && !contentType.contains("text/plain"))) {
            return true;
        }

        sendElmApp(ctx);
        return true;
    }

    private void sendElmApp(HttpContext ctx) {
        final StaticFile indexFile = staticFileService.get("/index.html");
        if (indexFile != null) {
            ctx.getResponse().setCode(ResponseCodes.OK);
            ctx.getResponse().sendFile(indexFile);
        }
    }
}
