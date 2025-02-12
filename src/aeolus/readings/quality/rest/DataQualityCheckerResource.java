package aeolus.readings.quality.rest;

import aeolus.readings.quality.CheckerConfig;
import aeolus.readings.quality.DataQualityCheckerDispatcher;
import aeolus.readings.quality.service.CheckerConfigService;
import dobby.annotations.Get;
import dobby.annotations.Post;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;
import dobby.util.json.NewJson;
import hades.annotations.AuthorizedOnly;
import hades.apidocs.annotations.ApiDoc;
import hades.apidocs.annotations.ApiResponse;

import java.util.UUID;

public class DataQualityCheckerResource {
    private static final String BASE_PATH = "/rest/data-quality-checker-config";
    private static final CheckerConfigService service = CheckerConfigService.getInstance();

    @AuthorizedOnly
    @Get(BASE_PATH)
    @ApiDoc(description = "Loads the quality checker configuration for the current user from the database or returns a new one if it doesn't exist.", summary = "Get the data quality checker configuration for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The data quality checker configuration for the current user.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void getCheckerConfigForUser(HttpContext context) {
        final UUID userId = getUserId(context);
        CheckerConfig config = service.findByUser(userId);

        if (config == null) {
            config = service.create(userId);
        }

        context.getResponse().setBody(config.toJson());
    }

    @AuthorizedOnly
    @Post(BASE_PATH + "/enable")
    @ApiDoc(description = "Enables the data quality checker for the current user.", summary = "Enable the data quality checker for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The data quality checker has been enabled.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void enableCheckerForUser(HttpContext context) {
        final UUID userId = getUserId(context);
        CheckerConfig config = service.findByUser(userId);

        if (config == null) {
            config = service.create(userId);
        }

        config.setEnabled(true);
        if (!service.save(config)) {
            context.getResponse().setCode(ResponseCodes.INTERNAL_SERVER_ERROR);
        }
    }

    @AuthorizedOnly
    @Post(BASE_PATH + "/disable")
    @ApiDoc(description = "Disables the data quality checker for the current user.", summary = "Disables the data quality checker for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The data quality checker has been disabled.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void disableCheckerForUser(HttpContext context) {
        final UUID userId = getUserId(context);
        CheckerConfig config = service.findByUser(userId);

        if (config == null) {
            config = service.create(userId);
        }

        config.setEnabled(false);
        if (!service.save(config)) {
            context.getResponse().setCode(ResponseCodes.INTERNAL_SERVER_ERROR);
        }
    }

    @AuthorizedOnly
    @Post(BASE_PATH + "/start-time")
    @ApiDoc(description = "Sets the start time for the data quality checker for the current user.", summary = "Sets the start time for the data quality checker for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The start time has been set.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void setStartTimeForUser(HttpContext context) {
        final UUID userId = getUserId(context);
        final NewJson body = context.getRequest().getBody();

        if (!body.hasKey("hour") || !body.hasKey("minute")) {
            context.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            return;
        }

        CheckerConfig config = service.findByUser(userId);

        if (config == null) {
            config = service.create(userId);
        }

        final int startHour = body.getInt("hour");
        final int startMinute = body.getInt("minute");

        config.setStartHour(startHour);
        config.setStartMinute(startMinute);

        if (!service.save(config)) {
            context.getResponse().setCode(ResponseCodes.INTERNAL_SERVER_ERROR);
        }
    }

    @AuthorizedOnly
    @Post(BASE_PATH + "/run")
    @ApiDoc(description = "Runs the data quality checker for the current user.", summary = "Runs the data quality checker for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The data quality checker has been run.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void runCheckerForUser(HttpContext context) {
        final UUID userId = getUserId(context);
        CheckerConfig config = service.findByUser(userId);

        if (config == null) {
            config = service.create(userId);
        }

        DataQualityCheckerDispatcher.getInstance().runForUser(config);
    }

    private UUID getUserId(HttpContext context) {
        return UUID.fromString(context.getSession().get("userId"));
    }
}
