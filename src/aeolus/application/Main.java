package aeolus.application;

import aeolus.readings.quality.DataQualityCheckerDispatcher;
import common.inject.api.RegisterFor;
import dobby.task.ISchedulerService;
import hades.Hades;
import hades.HadesDependencyProvider;

import java.util.concurrent.TimeUnit;

@RegisterFor(Main.class)
public class Main extends Hades {
    private final ISchedulerService schedulerService;
    private final DataQualityCheckerDispatcher dataQualityCheckerDispatcher;

    public Main(HadesDependencyProvider hadesDependencyProvider, ISchedulerService schedulerService, DataQualityCheckerDispatcher dataQualityCheckerDispatcher) {
        super(hadesDependencyProvider);
        this.schedulerService = schedulerService;
        this.dataQualityCheckerDispatcher = dataQualityCheckerDispatcher;
    }

    public static void main(String[] args) {
        startApplication(Main.class);
    }

    @Override
    public void postStart() {
        schedulerService.addRepeating(dataQualityCheckerDispatcher::run, 5, TimeUnit.MINUTES);
    }
}
