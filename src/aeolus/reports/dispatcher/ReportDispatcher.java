package aeolus.reports.dispatcher;

import aeolus.mail.Attachment;
import aeolus.mail.Mail;
import aeolus.mail.service.MailService;
import aeolus.reports.Report;
import aeolus.reports.ReportScheduleDay;
import aeolus.reports.TriggerType;
import aeolus.reports.rendering.ReportPdfRenderer;
import aeolus.reports.service.ReportService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import common.logger.Logger;
import dobby.files.StaticFile;
import hades.messaging.service.MessageService;
import hades.user.User;
import hades.user.service.UserService;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;

@RegisterFor(ReportDispatcher.class)
public class ReportDispatcher {
    private static final Logger LOGGER = new Logger(ReportDispatcher.class);
    private final ReportPdfRenderer  renderer;
    private final MailService mailService;
    private final ReportService reportService;
    private final MessageService messageService;
    private final UserService userService;

    @Inject
    public ReportDispatcher(ReportPdfRenderer renderer, MailService mailService, ReportService reportService, MessageService messageService, UserService userService) {
        this.renderer = renderer;
        this.mailService = mailService;
        this.reportService = reportService;
        this.messageService = messageService;
        this.userService = userService;
    }

    public void run() {
        final List<ReportScheduleDay> runFor = isFirstOfWeekMonthOrYear();
        if (runFor.isEmpty()) {
            return;
        }
        LOGGER.debug("Running scheduled reports for " + runFor);

        final Report[] reports = Arrays.stream(reportService.findAll()).filter(report -> report.getTrigger() == TriggerType.SCHEDULED && runFor.contains(report.getReportScheduleDay())).toArray(Report[]::new);
        final Calendar now = Calendar.getInstance();
        final int month = now.get(Calendar.MONTH) + 1;
        final int year = now.get(Calendar.YEAR);

        for (Report report : reports) {
            try {
                if (!shouldRun(report)) {
                    continue;
                }

                LOGGER.debug("Running report with id " + report.getName() + " of user " + report.getOwner());
                final StaticFile pdf = renderer.render(report, month, year);
                final User user = userService.find(report.getOwner());
                if (user == null) {
                    LOGGER.error("User with id " + report.getOwner() + " not found for report " + report.getName());
                    continue;
                }

                LOGGER.debug("Sending report with id " + report.getName() + " of user " + report.getOwner());
                final Mail mail = new Mail(user.getMail(), "Bericht " + report.getName() + " " + month + "." + year, "");
                final Attachment attachment = new Attachment(report.getName() + "-" + year + "-" + month + ".pdf", pdf);
                mail.addAttachment(attachment);
                mailService.send(mail);
            } catch (Exception e) {
                LOGGER.error("an error occurred while running report with id " + report.getName() + " of user " + report.getOwner());
                LOGGER.trace(e);
                messageService.update(messageService.newSystemMessage(report.getOwner(), "An error occurred while generating your report " + report.getName() + ". " + e.getMessage()));
            }
        }
    }

    private boolean shouldRun(Report report) throws ParseException {
        final Calendar now = Calendar.getInstance();
        SimpleDateFormat format = new SimpleDateFormat("HH:mm");

        final Date currentDate = format.parse(now.get(Calendar.HOUR_OF_DAY) + ":" + now.get(Calendar.MINUTE));
        final Date startDate = format.parse(report.getScheduleHour() + ":" + report.getScheduleMinute());

        final int diff = (int) ((currentDate.getTime() - startDate.getTime()) / 60000);

        return diff >= 0 && diff < 5;
    }

    private List<ReportScheduleDay> isFirstOfWeekMonthOrYear() {
        final List<ReportScheduleDay> runFor =  new ArrayList<>();

        final Calendar now = Calendar.getInstance();
        if (now.get(Calendar.DAY_OF_WEEK) == Calendar.MONDAY) {
            runFor.add(ReportScheduleDay.FIRST_DAY_OF_WEEK);
        }

        if (now.get(Calendar.DAY_OF_MONTH) == 1) {
            runFor.add(ReportScheduleDay.FIRST_DAY_OF_MONTH);
        }

        if (now.get(Calendar.DAY_OF_YEAR) == 1) {
            runFor.add(ReportScheduleDay.FIRST_DAY_OF_YEAR);
        }

        return runFor;
    }
}
