package aeolus.readings.quality.rest;

import aeolus.readings.quality.CheckerConfig;
import aeolus.readings.quality.service.CheckerConfigService;
import dobby.annotations.Get;
import dobby.annotations.Post;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;
import dobby.util.json.NewJson;
import hades.annotations.AuthorizedOnly;

import java.util.UUID;

public class DataQualityCheckerResource {
    private static final String BASE_PATH = "/rest/data-quality-checker-config";
    private static final CheckerConfigService service = CheckerConfigService.getInstance();

    @AuthorizedOnly
    @Get(BASE_PATH)
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
    public void enableCheckerForUser(HttpContext context) {
        final UUID userId = getUserId(context);
        CheckerConfig config = service.findByUser(userId);

        if (config == null) {
            config = service.create(userId);
        }

        config.setEnabled(true);
        service.save(config);
    }

    @AuthorizedOnly
    @Post(BASE_PATH + "/disable")
    public void disableCheckerForUser(HttpContext context) {
        final UUID userId = getUserId(context);
        CheckerConfig config = service.findByUser(userId);

        if (config == null) {
            config = service.create(userId);
        }

        config.setEnabled(false);
        service.save(config);
    }

    @AuthorizedOnly
    @Post(BASE_PATH + "/start-time")
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

        service.save(config);
    }

    private UUID getUserId(HttpContext context) {
        return UUID.fromString(context.getSession().get("userId"));
    }
}
