package aeolus.readings.quality.rest;

import aeolus.readings.Reading;
import aeolus.readings.quality.InterpolationService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.annotations.Get;
import dobby.io.HttpContext;
import dobby.util.Tupel;
import dobby.util.json.NewJson;
import hades.annotations.AuthorizedOnly;
import hades.apidocs.annotations.ApiDoc;
import hades.apidocs.annotations.ApiResponse;
import hades.util.UserUtil;

import java.util.List;
import java.util.UUID;

@RegisterFor(InterpolationResource.class)
public class InterpolationResource {
    private static final String BASE_PATH = "/rest/interpolation";
    private final InterpolationService service;

    @Inject
    public InterpolationResource(InterpolationService service) {
        this.service = service;
    }

    @AuthorizedOnly
    @Get(BASE_PATH)
    @ApiDoc(description = "Interpolates missing readings (holes) for the current user based on their data.", summary = "Interpolate missing readings for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The interpolated readings and holes that could not be interpolated.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void getInterpolation(HttpContext context) {
        final UUID userId = UserUtil.getCurrentUserId(context);
        final Tupel<List<Reading>, List<String>> result = service.interpolate(userId);

        final NewJson response = new NewJson();
        response.setList("interpolatedReadings", result._1().stream().map(r -> (Object) r.toJson()).toList());
        response.setList("notInterpolatedHoles", result._2().stream().map(hole -> (Object) hole).toList());

        context.getResponse().setBody(response);
    }
}
