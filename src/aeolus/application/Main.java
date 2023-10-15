package aeolus.application;

import dobby.Dobby;
import dobby.util.logging.Logger;
import thot.connector.Connector;

public class Main {
    public static void main(String[] args) {
        boolean thotInstanceRunning = Connector.write("testBucket", "isInstanceRunning", "true");
        if (!thotInstanceRunning) {
            new Logger(Main.class).error("Thot instance not running");
            return;
        }
        Dobby.startApplication(Main.class);
    }
}
