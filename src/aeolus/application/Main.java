package aeolus.application;

import aeolus.mail.service.MailService;
import aeolus.readings.quality.DataQualityCheckerDispatcher;
import aeolus.reports.dispatcher.ReportDispatcher;
import common.inject.api.RegisterFor;
import dobby.task.ISchedulerService;
import hades.Hades;
import hades.HadesDependencyProvider;

import java.util.concurrent.TimeUnit;

@RegisterFor(Main.class)
public class Main extends Hades {
    private final ISchedulerService schedulerService;
    private final DataQualityCheckerDispatcher dataQualityCheckerDispatcher;
    private final ReportDispatcher reportDispatcher;

    public Main(HadesDependencyProvider hadesDependencyProvider, ISchedulerService schedulerService, DataQualityCheckerDispatcher dataQualityCheckerDispatcher, ReportDispatcher reportDispatcher, MailService mailService) {
        super(hadesDependencyProvider);
        this.schedulerService = schedulerService;
        this.dataQualityCheckerDispatcher = dataQualityCheckerDispatcher;
        this.reportDispatcher = reportDispatcher;
    }

    public static void main(String[] args) {
        startApplication(Main.class);
    }

    @Override
    public void postStart() {
        super.postStart();
        schedulerService.addRepeating(dataQualityCheckerDispatcher::run, 5, TimeUnit.MINUTES);
        schedulerService.addRepeating(reportDispatcher::run, 5, TimeUnit.MINUTES);
    }
}
