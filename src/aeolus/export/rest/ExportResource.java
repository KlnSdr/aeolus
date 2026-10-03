package aeolus.export.rest;

import aeolus.export.Export;
import aeolus.export.ExportService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.annotations.Get;
import dobby.io.HttpContext;
import hades.annotations.AuthorizedOnly;
import hades.apidocs.annotations.ApiDoc;
import hades.apidocs.annotations.ApiResponse;
import hades.util.UserUtil;

import java.util.UUID;

@RegisterFor(ExportResource.class)
public class ExportResource {
    private static final String BASE_PATH = "/export";
    private final ExportService exportService;

    @Inject
    public ExportResource(ExportService exportService) {
        this.exportService = exportService;
    }

    @AuthorizedOnly
    @Get(BASE_PATH)
    @ApiDoc(description = "Exports all readings, monthly values, and tariff prices for the current user in CSV format.", summary = "Export data for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The exported data in CSV format.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void downloadExport(HttpContext context) {
        final UUID userId = UserUtil.getCurrentUserId(context);

        final Export export = exportService.export(userId);
        context.getResponse().sendFile(export.toCSV());
    }
}
