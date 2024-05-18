package aeolus.filter;

import dobby.filter.Filter;
import dobby.filter.FilterType;
import dobby.io.HttpContext;
import dobby.io.response.Response;
import dobby.io.response.ResponseCodes;
import dobby.session.Session;
import dobby.util.Config;
import hades.filter.FilterOrder;
import hades.user.service.UserService;

import java.util.List;

public class AeolusAuthorizedRedirectFilter implements Filter {
    private static final List<String> pathsToIgnore = List.of("/", "/index.html", "/month", "/month/", "/month/index.html", "/year", "/year/", "/year/index.html");

    @Override
    public String getName() {
        return "aeolus-authorized-redirect-pre-filter";
    }

    @Override
    public FilterType getType() {
        return FilterType.PRE;
    }

    @Override
    public int getOrder() {
        return FilterOrder.AUTHORIZED_REDIRECT_PRE_FILTER.getOrder();
    }

    @Override
    public boolean run(HttpContext httpContext) {
        final String path = httpContext.getRequest().getPath();
        final Session session = httpContext.getSession();

        if (UserService.getInstance().isLoggedIn(session)) {
            return true;
        }

        if (pathsToIgnore.contains(path.toLowerCase())) {
            final Response response = httpContext.getResponse();

            response.setHeader("location", Config.getInstance().getString("hades.context", "") + "/hades/login/");
            response.setCode(ResponseCodes.FOUND);

            return false;
        }
        return true;
    }
}
