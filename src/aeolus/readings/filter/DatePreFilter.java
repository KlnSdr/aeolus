package aeolus.readings.filter;

import dobby.filter.Filter;
import dobby.filter.FilterType;
import dobby.io.HttpContext;
import dobby.io.request.RequestTypes;
import dobby.io.response.ResponseCodes;
import dobby.util.Json;
import dobby.util.json.NewJson;

import static aeolus.util.IsoDate.isValidIsoDate;

public class DatePreFilter implements Filter {
    @Override
    public String getName() {
        return "date";
    }

    @Override
    public FilterType getType() {
        return FilterType.PRE;
    }

    @Override
    public int getOrder() {
        return 0;
    }

    @Override
    public boolean run(HttpContext httpContext) {
        if (!httpContext.getRequest().getPath().equals("/readings")) {
            return true;
        }

        if (httpContext.getRequest().getType() == RequestTypes.POST) {
            return filterPost(httpContext);
        }
        return true;
    }

    private boolean filterPost(HttpContext httpContext) {

        final NewJson body = httpContext.getRequest().getBody();

        if (!body.hasKeys("value", "date")) {
            final NewJson message = new NewJson();
            message.setString("msg", "Missing value or date");

            httpContext.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            httpContext.getResponse().setBody(message);
            return false;
        }

        final String isoDateString = httpContext.getRequest().getBody().getString("date");
        final String valueString = httpContext.getRequest().getBody().getString("value");

        try {
            Float.parseFloat(valueString);
        } catch (NumberFormatException e) {
            final NewJson message = new NewJson();
            message.setString("msg", "Invalid value: " + valueString);

            httpContext.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            httpContext.getResponse().setBody(message);
            return false;
        }

        if (!isValidIsoDate(isoDateString)) {
            final NewJson message = new NewJson();
            message.setString("msg", "Invalid ISO date: " + isoDateString);

            httpContext.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            httpContext.getResponse().setBody(message);
            return false;
        }

        return true;
    }
}
