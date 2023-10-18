package aeolus.readings.rest;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;
import aeolus.readings.service.ReadingService;
import dobby.annotations.Get;
import dobby.annotations.Post;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;
import dobby.util.Json;

import java.util.Arrays;
import java.util.Date;
import java.util.List;

import static aeolus.util.IsoDate.parseIsoDate;
import static aeolus.util.IsoDate.toIsoDateString;

public class ReadingRessource {

    @Get("/readings/{year}")
    public void getReadingsForYear(HttpContext context) {
        int year;
        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
        } catch (NumberFormatException e) {
            sendBadRequest(context, "Invalid year: " + context.getRequest().getParam("year"));
            return;
        }

        Reading[] readings = ReadingService.getInstance().find(year);

        Json json = new Json();
        List<Object> readingsList = List.of(Arrays.stream(readings).map(this::map).toArray(Json[]::new));
        json.setList("readings", readingsList);

        context.getResponse().setBody(json);
    }

    @Get("/readings/{year}/{month}")
    public void getReadingsForYearAndMonth(HttpContext context) {
        int year, month;

        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
            month = Integer.parseInt(context.getRequest().getParam("month"));
        } catch (NumberFormatException e) {
            sendBadRequest(context,
                    "Invalid year or month: " + context.getRequest().getParam("year") + "-" + context.getRequest().getParam("month"));
            return;
        }

        Reading[] readings;
        try {
            readings = ReadingService.getInstance().find(year, month);
        } catch (IllegalArgumentException e) {
            sendBadRequest(context, "Invalid month: " + month);
            return;
        }

        Json json = new Json();
        List<Object> readingsList = List.of(Arrays.stream(readings).map(this::map).toArray(Json[]::new));
        json.setList("readings", readingsList);

        context.getResponse().setBody(json);
    }

    @Get("/readings/{year}/{month}/{day}")
    public void getReadingsForYearMonthDay(HttpContext context) {
        int year, month, day;

        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
            month = Integer.parseInt(context.getRequest().getParam("month"));
            day = Integer.parseInt(context.getRequest().getParam("day"));
        } catch (NumberFormatException e) {
            sendBadRequest(context,
                    "Invalid year, month or day: " + context.getRequest().getParam("year") + "-" + context.getRequest().getParam("month") + "-" + context.getRequest().getParam("day"));
            return;
        }

        Reading reading;
        try {
            reading = ReadingService.getInstance().find(year, month, day);
        } catch (IllegalArgumentException e) {
            sendBadRequest(context, "Invalid date: " + year + "-" + month + "-" + day);
            return;
        } catch (NullPointerException e) {
            sendNotFound(context, "No reading found for date: " + year + "-" + month + "-" + day);
            return;
        }

        context.getResponse().setBody(map(reading));
    }

    @Post("/readings")
    public void addReading(HttpContext context) {
        Json json = context.getRequest().getBody();
        float value = Float.parseFloat(json.getString("value"));
        String isoDate = json.getString("date");
        Date date = parseIsoDate(isoDate);

        Reading reading = new Reading(value, date);
        boolean wasAdded;
        try {
            wasAdded = ReadingService.getInstance().add(reading);
        } catch (DuplicateEntryException e) {
            context.getResponse().setCode(ResponseCodes.CONFLICT);

            Json message = new Json();
            message.setString("msg", "Reading for date " + isoDate + " already exists");

            context.getResponse().setBody(message);
            return;
        }

        context.getResponse().setCode(wasAdded ? ResponseCodes.CREATED : ResponseCodes.INTERNAL_SERVER_ERROR);
    }

    private Json map(Reading reading) {
        Json json = new Json();
        json.setString("value", Float.toString(reading.getValue()));
        json.setString("date", toIsoDateString(reading.getDate()));
        return json;
    }

    private void sendNotFound(HttpContext ctx, String message) {
        ctx.getResponse().setCode(ResponseCodes.NOT_FOUND);

        Json json = new Json();
        json.setString("msg", message);

        ctx.getResponse().setBody(json);
    }

    private void sendBadRequest(HttpContext ctx, String message) {
        ctx.getResponse().setCode(ResponseCodes.BAD_REQUEST);

        Json json = new Json();
        json.setString("msg", message);

        ctx.getResponse().setBody(json);
    }
}
