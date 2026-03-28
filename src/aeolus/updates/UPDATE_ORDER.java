package aeolus.updates;

public enum UPDATE_ORDER {
    CREATE_BUCKETS(0),
    CHECKER_CONFIG_BUCKET(1),
    MONTHLY_VALUES_BUCKET(2),
    ADVANCED_MONTHLY_VALUES_BUCKET(3),
    REPORT_DEFINITIONS_BUCKET(4)
    ;

    private final int order;
    UPDATE_ORDER(int order) {
        this.order = order;
    }

    public int getOrder() {
        return order;
    }
}
