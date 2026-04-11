package aeolus.reports.rest;

import aeolus.mail.Mail;
import aeolus.mail.service.MailService;
import aeolus.reports.*;
import aeolus.reports.rendering.ReportPdfRenderer;
import aeolus.reports.service.ReportService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.annotations.Delete;
import dobby.annotations.Get;
import dobby.annotations.Post;
import dobby.files.StaticFile;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;
import dobby.util.json.NewJson;
import hades.annotations.AuthorizedOnly;
import hades.apidocs.annotations.ApiDoc;
import hades.apidocs.annotations.ApiResponse;
import hades.apidocs.annotations.ApiResponses;
import hades.common.ErrorResponses;

import java.io.IOException;
import java.time.LocalDate;
import java.time.Year;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import static hades.common.Util.prependZero;
import static hades.util.UserUtil.getCurrentUserId;

@RegisterFor(ReportResource.class)
public class ReportResource {
    private static final String BASE_PATH = "/rest/report";
    private final ReportService reportService;
    private final ReportPdfRenderer reportPdfRenderer;
    private final MailService mailService;

    @Inject
    public ReportResource(ReportService reportService,  ReportPdfRenderer reportPdfRenderer, MailService mailService) {
        this.reportService = reportService;
        this.reportPdfRenderer = reportPdfRenderer;
        this.mailService = mailService;
    }

    @ApiDoc( summary = "Get all reports", description = "Returns all reports owned by the currently authenticated user", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "OK")
    @AuthorizedOnly
    @Get(BASE_PATH)
    public void getAllReports(HttpContext context) {
        final UUID owner = getCurrentUserId(context);
        final Report[] reports = reportService.find(owner);

        final NewJson json = new NewJson();
        json.setList("reports", Stream.of(reports).map(Report::toJson).map(j -> (Object) j).toList());

        context.getResponse().setCode(ResponseCodes.OK);
        context.getResponse().setBody(json);
    }

    @ApiDoc(summary = "Delete report", description = "Deletes a report owned by the authenticated user by report ID", baseUrl = BASE_PATH)
    @ApiResponse(code = 204, message = "Report deleted successfully")
    @ApiResponse(code = 400, message = "Invalid report ID format")
    @ApiResponse(code = 404, message = "Report not found")
    @ApiResponse(code = 500, message = "Internal server error while deleting report")
    @AuthorizedOnly
    @Delete(BASE_PATH + "/id/{reportId}")
    public void deleteReport(HttpContext context) {
        final UUID owner = getCurrentUserId(context);
        final String reportIdStr = context.getRequest().getParam("reportId");
        UUID reportId;
        try {
            reportId = UUID.fromString(reportIdStr);
        } catch (IllegalArgumentException e) {
            ErrorResponses.badRequest(context.getResponse(), "Invalid report ID format");
            return;
        }
        final Report report = reportService.find(owner, reportId);
        if (report == null) {
            ErrorResponses.notFound(context.getResponse(), "Report with id " + reportIdStr + " not found");
            return;
        }
        if (reportService.delete(report)) {
            context.getResponse().setCode(ResponseCodes.NO_CONTENT);
        } else {
            ErrorResponses.internalError(context.getResponse(), "Failed to delete report");
        }
    }

    @ApiDoc(summary = "Create report", description = "Creates a new report for the authenticated user. Supports scheduled and immediate triggers.", baseUrl = BASE_PATH)
    @ApiResponse(code = 201, message = "Report created successfully")
    @ApiResponse(code = 400, message = "Invalid report input or schedule definition")
    @ApiResponse(code = 500, message = "Failed to create report")
    @AuthorizedOnly
    @Post(BASE_PATH)
    public void createReport(HttpContext context) {
        final UUID owner = getCurrentUserId(context);
        final NewJson body = context.getRequest().getBody();

        if (!validateBasicReportInfo(body)) {
            ErrorResponses.badRequest(context.getResponse(), "Invalid report information");
            return;
        }

        final String name = body.getString("name");
        final ReportType reportType = ReportType.valueOf(body.getString("reportType"));
        final List<ReportFeatures> reportFeatures = body.getList("reportFeatures").stream().map( o -> ReportFeatures.valueOf((String) o)).toList();
        final TriggerType trigger = TriggerType.valueOf(body.getString("trigger"));
        ReportScheduleDay scheduleDay = ReportScheduleDay.UNSET;
        int scheduleHour = 0;
        int scheduleMinute = 0;

        if (trigger == TriggerType.SCHEDULED) {
            if (!validateTriggerDefinition(body)) {
                ErrorResponses.badRequest(context.getResponse(), "Invalid trigger definition");
                return;
            }
            final String scheduleTime = body.getString("scheduleTime");
            if (!scheduleTime.matches("\\d{2}:\\d{2}")) {
                ErrorResponses.badRequest(context.getResponse(), "Invalid schedule time format. Expected HH:mm");
                return;
            }
            scheduleHour = Integer.parseInt(scheduleTime.split(":")[0]);
            scheduleMinute = Integer.parseInt(scheduleTime.split(":")[1]);

            scheduleDay = ReportScheduleDay.valueOf(body.getString("scheduleDay"));
        }

        final Report report = new Report();
        report.setOwner(owner);
        report.setName(name);
        report.setReportType(reportType);
        report.setReportFeatures(reportFeatures);
        report.setTrigger(trigger);
        report.setReportScheduleDay(scheduleDay);
        report.setScheduleHour(scheduleHour);
        report.setScheduleMinute(scheduleMinute);

        if (reportService.update(report)) {
            context.getResponse().setCode(ResponseCodes.CREATED);
            context.getResponse().setBody(report.toJson());
        } else {
            ErrorResponses.internalError(context.getResponse(), "Failed to create report");
        }
    }

    @ApiDoc(summary = "Render report", description = "Generates a rendered file (e.g. PDF) for a report for the current month and year", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "File rendered successfully")
    @ApiResponse(code = 404, message = "Report not found")
    @ApiResponse(code = 500, message = "Rendering failure")
    @AuthorizedOnly
    @Get(BASE_PATH + "/id/{reportId}/render")
    public void renderReport(HttpContext context) {
        final Report report = reportService.find(getCurrentUserId(context), UUID.fromString(context.getRequest().getParam("reportId")));
        if (report == null) {
            ErrorResponses.notFound(context.getResponse(), "Report not found");
            return;
        }

        int currentYear = Year.now().getValue();
        int currentMonth = LocalDate.now().getMonthValue();
        try {
            context.getResponse().sendFile(reportPdfRenderer.render(report, currentMonth, currentYear));
        } catch (Exception e) {
            ErrorResponses.internalError(context.getResponse(), "Failed to render report. " + e.getMessage());
        }
    }

    private boolean validateBasicReportInfo(NewJson body) {
        if (body == null) {
            return false;
        }
        if (!body.hasKeys("reportType", "name", "reportFeatures", "trigger")) {
            return false;
        }
        if (body.getString("reportType") == null || body.getString("reportType").isBlank() || body.getString("name") == null || body.getString("name").isBlank() || body.getString("trigger") == null || body.getString("trigger").isBlank()) {
            return false;
        }
        try {
            ReportType.valueOf(body.getString("reportType"));
            TriggerType.valueOf(body.getString("trigger"));
        } catch (IllegalArgumentException e) {
            return false;
        }

        if (body.getList("reportFeatures") == null) {
            return false;
        }

        final List<Object> reportFeatures = body.getList("reportFeatures");
        for (Object feature : reportFeatures) {
            if (!(feature instanceof String) || ((String) feature).isBlank()) {
                return false;
            }
            try {
                ReportFeatures.valueOf((String) feature);
            } catch (IllegalArgumentException e) {
                return false;
            }
        }

        return true;
    }

    private boolean validateTriggerDefinition(NewJson body) {
        if (!body.hasKeys("scheduleDay", "scheduleTime")) {
            return false;
        }
        try {
            ReportScheduleDay.valueOf(body.getString("scheduleDay"));
        } catch (IllegalArgumentException e) {
            return false;
        }

        if (body.getString("scheduleTime") == null || body.getString("scheduleTime").isBlank()) {
            return false;
        }

        return true;
    }
}
