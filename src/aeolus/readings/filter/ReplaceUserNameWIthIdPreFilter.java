package aeolus.readings.filter;

import dobby.filter.Filter;
import dobby.filter.FilterType;
import dobby.io.HttpContext;
import hades.user.User;
import hades.user.service.UserService;

import java.util.regex.Pattern;

public class ReplaceUserNameWIthIdPreFilter implements Filter {
    private static final Pattern UUID_PATTER = Pattern.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");

    @Override
    public String getName() {
        return "ReplaceUserNameWIthIdPreFilter";
    }

    @Override
    public FilterType getType() {
        return FilterType.PRE;
    }

    @Override
    public int getOrder() {
        return 20;
    }

    @Override
    public boolean run(HttpContext httpContext) {
        final String route = httpContext.getRequest().getPath();

        if (!route.startsWith("/rest/readings/publicdataset/user")) {
            return true;
        }

        final String[] parts = route.split("/rest/readings/publicdataset/user");
        if (parts.length != 2) {
            return true;
        }

        final String id = parts[1].substring(1);
        if (UUID_PATTER.matcher(id).matches()) {
            return true;
        }

        final User[] user = UserService.getInstance().findByName(id);
        if (user.length != 1) {
            return true;
        }

        httpContext.getRequest().setPath("/rest/readings/publicdataset/user/" + user[0].getId().toString());

        return true;
    }
}
