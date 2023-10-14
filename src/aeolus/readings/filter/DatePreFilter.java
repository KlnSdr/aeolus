package aeolus.readings.filter;

import dobby.filter.Filter;
import dobby.filter.FilterType;
import dobby.io.HttpContext;
import dobby.io.request.Request;
import dobby.io.request.RequestTypes;
import dobby.io.response.ResponseCodes;
import dobby.util.Json;

import java.time.format.DateTimeParseException;
import java.util.List;

import static aeolus.util.IsoDate.isValidIsoDate;
import static aeolus.util.IsoDate.parseIsoDate;

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

        Json body = httpContext.getRequest().getBody();

        if (!body.hasKeys(new String[]{"value", "date"})) {
            Json message = new Json();
            message.setString("msg", "Missing value or date");

            httpContext.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            httpContext.getResponse().setBody(message.toString());
            return false;
        }

        String isoDateString = httpContext.getRequest().getBody().getString("date");
        String valueString = httpContext.getRequest().getBody().getString("value");

        try {
            Float.parseFloat(valueString);
        } catch (NumberFormatException e) {
            Json message = new Json();
            message.setString("msg", "Invalid value: " + valueString);

            httpContext.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            httpContext.getResponse().setBody(message.toString());
            return false;
        }

        if (!isValidIsoDate(isoDateString)) {
            Json message = new Json();
            message.setString("msg", "Invalid ISO date: " + isoDateString);

            httpContext.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            httpContext.getResponse().setBody(message.toString());
            return false;
        }

        return true;
    }
}
