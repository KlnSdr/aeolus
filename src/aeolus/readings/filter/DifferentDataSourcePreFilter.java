package aeolus.readings.filter;

import dobby.filter.Filter;
import dobby.filter.FilterType;
import dobby.io.HttpContext;
import dobby.io.request.RequestTypes;
import dobby.io.response.ResponseCodes;
import hades.authorized.Group;
import hades.authorized.service.GroupService;
import hades.user.User;
import hades.user.service.UserService;

import java.util.UUID;

public class DifferentDataSourcePreFilter implements Filter {
    @Override
    public String getName() {
        return "DifferentDataSourcePreFilter";
    }

    @Override
    public FilterType getType() {
        return FilterType.PRE;
    }

    @Override
    public int getOrder() {
        return 21;
    }

    @Override
    public boolean run(HttpContext httpContext) {
        if (!httpContext.getRequest().getQueryKeys().contains("dataSource")) {
            return true;
        }

        final String dataSource = httpContext.getRequest().getQuery("dataSource").getFirst();

        final UUID dataSourceUserId;
        try {
            dataSourceUserId = UUID.fromString(dataSource);
        } catch (IllegalArgumentException e) {
            httpContext.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            httpContext.getResponse().setBody("Invalid dataSource: " + dataSource);
            return false;
        }

        final User dataSourceOwner = UserService.getInstance().find(dataSourceUserId);

        if (dataSourceOwner == null) {
            httpContext.getResponse().setCode(ResponseCodes.NOT_FOUND);
            httpContext.getResponse().setBody("User not found: " + dataSource);
            return false;
        }

        final UUID currentUserId = UUID.fromString(httpContext.getSession().get("userId"));

        final User currentUser = UserService.getInstance().find(currentUserId);

        if (currentUser == null) {
            httpContext.getResponse().setCode(ResponseCodes.UNAUTHORIZED);
            httpContext.getResponse().setBody("User not found: " + currentUserId);
            return false;
        }

        final Group[] groups = GroupService.getInstance().findGroupsByUser(currentUserId);
        boolean hasNeededGroup = false;
        for (Group group : groups) {
            if (group.getName().equals(dataSourceUserId + "-guest")) {
                hasNeededGroup = true;
                break;
            }
        }

        if (!hasNeededGroup) {
            httpContext.getResponse().setCode(ResponseCodes.UNAUTHORIZED);
            httpContext.getResponse().setBody("User does not expose a public dataset");
            return false;
        }

        if (!httpContext.getRequest().getType().equals(RequestTypes.GET)) {
            httpContext.getResponse().setCode(ResponseCodes.UNAUTHORIZED);
            httpContext.getResponse().setBody("Only GET requests are allowed for public data sources");
            return false;
        }

        return true;
    }
}
