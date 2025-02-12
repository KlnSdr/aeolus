package aeolus.readings.rest;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;
import aeolus.readings.service.ReadingService;
import dobby.annotations.Get;
import dobby.annotations.Post;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;
import dobby.util.json.NewJson;
import hades.annotations.AuthorizedOnly;
import hades.apidocs.annotations.ApiDoc;
import hades.apidocs.annotations.ApiResponse;
import hades.authorized.Group;
import hades.authorized.service.GroupService;
import hades.common.ErrorResponses;
import hades.user.User;
import hades.user.service.UserService;

import java.time.Year;
import java.util.*;

import static aeolus.util.IsoDate.parseIsoDate;

public class ReadingResource {
    private static final String BASE_PATH = "/rest/readings";

    @AuthorizedOnly
    @Get(BASE_PATH + "/last")
    @ApiDoc(description = "Returns the last reading for the current user.", summary = "Get the last reading for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The last reading for the current user.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 404, message = "No reading found.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void getLastReading(HttpContext context) {
        int year = Year.now().getValue();
        Reading[] readings = ReadingService.getInstance().find(getUserId(context), year);

        if (readings.length == 0) {
            readings = ReadingService.getInstance().find(getUserId(context), year - 1);
        }

        if (readings.length == 0) {
            readings = ReadingService.getInstance().find(getUserId(context), year - 2);
        }

        if (readings.length == 0) {
            ErrorResponses.notFound(context.getResponse(), "Could not find the last reading");
            return;
        }

        Arrays.sort(readings, Comparator.comparing(Reading::getDate));

        final Reading lastReading = readings[readings.length - 1];
        context.getResponse().setBody(lastReading.toJson());
    }

    @AuthorizedOnly
    @Get(BASE_PATH + "/{year}")
    @ApiDoc(description = "Returns all readings for the given year.", summary = "Get all readings for the given year.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "All readings for the given year.")
    @ApiResponse(code = 400, message = "Invalid year.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void getReadingsForYear(HttpContext context) {
        int year;
        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
        } catch (NumberFormatException e) {
            sendBadRequest(context, "Invalid year: " + context.getRequest().getParam("year"));
            return;
        }

        Reading[] readings = ReadingService.getInstance().find(getUserId(context), year);
        Arrays.sort(readings, Comparator.comparing(Reading::getDate));

        final NewJson json = new NewJson();
        List<Object> readingsList = List.of(Arrays.stream(readings).map(this::map).toArray(NewJson[]::new));
        json.setList("readings", readingsList);

        context.getResponse().setBody(json);
    }

    @AuthorizedOnly
    @Get(BASE_PATH + "/{year}/{month}")
    @ApiDoc(description = "Returns all readings for the given year and month.", summary = "Get all readings for the given year and month.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "All readings for the given year and month.")
    @ApiResponse(code = 400, message = "Invalid year or month.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void getReadingsForYearAndMonth(HttpContext context) {
        int year, month;

        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
            month = Integer.parseInt(context.getRequest().getParam("month"));
        } catch (NumberFormatException e) {
            sendBadRequest(context, "Invalid year or month: " + context.getRequest().getParam("year") + "-" + context.getRequest().getParam("month"));
            return;
        }

        Reading[] readings;
        try {
            readings = ReadingService.getInstance().find(getUserId(context), year, month);
            Arrays.sort(readings, Comparator.comparing(Reading::getDate));
        } catch (IllegalArgumentException e) {
            sendBadRequest(context, "Invalid month: " + month);
            return;
        }

        final NewJson json = new NewJson();
        List<Object> readingsList = List.of(Arrays.stream(readings).map(this::map).toArray(NewJson[]::new));
        json.setList("readings", readingsList);

        context.getResponse().setBody(json);
    }

    @AuthorizedOnly
    @Get(BASE_PATH + "/{year}/{month}/{day}")
    @ApiDoc(description = "Returns the reading for the given year, month and day.", summary = "Get the reading for the given year, month and day.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The reading for the given year, month and day.")
    @ApiResponse(code = 400, message = "Invalid year, month or day.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 404, message = "No reading found.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void getReadingsForYearMonthDay(HttpContext context) {
        int year, month, day;

        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
            month = Integer.parseInt(context.getRequest().getParam("month"));
            day = Integer.parseInt(context.getRequest().getParam("day"));
        } catch (NumberFormatException e) {
            sendBadRequest(context, "Invalid year, month or day: " + context.getRequest().getParam("year") + "-" + context.getRequest().getParam("month") + "-" + context.getRequest().getParam("day"));
            return;
        }

        Reading reading;
        try {
            reading = ReadingService.getInstance().find(getUserId(context), year, month, day);
        } catch (IllegalArgumentException e) {
            sendBadRequest(context, "Invalid date: " + year + "-" + month + "-" + day);
            return;
        } catch (NullPointerException e) {
            sendNotFound(context, "No reading found for date: " + year + "-" + month + "-" + day);
            return;
        }

        context.getResponse().setBody(map(reading));
    }

    @AuthorizedOnly
    @Post(BASE_PATH)
    @ApiDoc(description = "Adds a new reading.", summary = "Add a new reading.", baseUrl = BASE_PATH)
    @ApiResponse(code = 201, message = "The reading has been added.")
    @ApiResponse(code = 400, message = "Invalid date or value.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 409, message = "Reading for the given date already exists.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void addReading(HttpContext context) {
        final NewJson json = context.getRequest().getBody();
        float value = Float.parseFloat(json.getString("value"));
        String isoDate = json.getString("date");
        Date date = parseIsoDate(isoDate);

        Reading reading = new Reading(value, date, getUserId(context));
        boolean wasAdded;
        try {
            wasAdded = ReadingService.getInstance().add(reading);
        } catch (DuplicateEntryException e) {
            context.getResponse().setCode(ResponseCodes.CONFLICT);

            final NewJson message = new NewJson();
            message.setString("msg", "Reading for date " + isoDate + " already exists");

            context.getResponse().setBody(message);
            return;
        }

        context.getResponse().setCode(wasAdded ? ResponseCodes.CREATED : ResponseCodes.INTERNAL_SERVER_ERROR);
    }

    @Get(BASE_PATH + "/publicdataset/user/{id}")
    @ApiDoc(description = "Checks if the user exposes a public dataset.", summary = "Check if the user exposes a public dataset.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The user exposes a public dataset.")
    @ApiResponse(code = 401, message = "The user does not expose a public dataset.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void doesUserExposeAPublicDataset(HttpContext context) {
        final UUID userId = UUID.fromString(context.getRequest().getParam("id"));
        final User user = UserService.getInstance().find(userId);

        final String userGuestGroup = user.getId().toString() + "-guest";
        final Group group = GroupService.getInstance().findByName(userGuestGroup);

        final NewJson message = new NewJson();
        message.setString("msg", "User does not expose a public dataset");

        if (group == null) {
            context.getResponse().setCode(ResponseCodes.UNAUTHORIZED);
            context.getResponse().setBody(message);
            return;
        }

        message.setString("id", user.getId().toString());

        context.getResponse().setCode(ResponseCodes.OK);
        context.getResponse().setBody(message);
    }

    private UUID getUserId(HttpContext context) {
        // change user context if dataSource is set
        if (!context.getRequest().getQueryKeys().contains("dataSource")) {
            return UUID.fromString(context.getSession().get("userId"));
        }

        return UUID.fromString(context.getRequest().getQuery("dataSource").getFirst());
    }

    private NewJson map(Reading reading) {
        return reading.toJson();
    }

    private void sendNotFound(HttpContext ctx, String message) {
        ctx.getResponse().setCode(ResponseCodes.NOT_FOUND);

        final NewJson json = new NewJson();
        json.setString("msg", message);

        ctx.getResponse().setBody(json);
    }

    private void sendBadRequest(HttpContext ctx, String message) {
        ctx.getResponse().setCode(ResponseCodes.BAD_REQUEST);

        final NewJson json = new NewJson();
        json.setString("msg", message);

        ctx.getResponse().setBody(json);
    }
}
