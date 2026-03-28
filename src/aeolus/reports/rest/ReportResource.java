package aeolus.reports.rest;

import aeolus.reports.*;
import aeolus.reports.service.ReportService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.annotations.Delete;
import dobby.annotations.Get;
import dobby.annotations.Post;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;
import dobby.util.json.NewJson;
import hades.annotations.AuthorizedOnly;
import hades.common.ErrorResponses;

import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import static hades.util.UserUtil.getCurrentUserId;

@RegisterFor(ReportResource.class)
public class ReportResource {
    private static final String BASE_PATH = "/rest/report";
    private final ReportService reportService;

    @Inject
    public ReportResource(ReportService reportService) {
        this.reportService = reportService;
    }

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

    @AuthorizedOnly
    @Post(BASE_PATH + "/id/{reportId}/render")
    public void renderReport(HttpContext context) {

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

        if (body.getList("reportFeatures") == null || body.getList("reportFeatures").isEmpty()) {
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
