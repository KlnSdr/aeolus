package aeolus.application;

import aeolus.readings.quality.DataQualityCheckerDispatcher;
import dobby.task.SchedulerService;
import hades.Hades;

import java.util.concurrent.TimeUnit;

public class Main extends Hades {
    public static void main(String[] args) {
        new Main().startApplication(Main.class);
    }

    @Override
    public void postStart() {
        SchedulerService.getInstance().addRepeating(() -> DataQualityCheckerDispatcher.getInstance().run(), 5, TimeUnit.MINUTES);
    }
}
