package aeolus.util;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.regex.Pattern;

public class IsoDate {

    public static boolean isValidIsoDate(String isoDate) {
        return isoDate == null || Pattern.matches("\\d{4}-\\d{2}-\\d{2}", isoDate);
    }

    public static String toIsoDateString(Date date) {
        DateFormat format = new SimpleDateFormat("yyyy-MM-dd");
        return format.format(date);
    }

    public static Date parseIsoDate(String isoDate) {
        LocalDate localDate = LocalDate.parse(isoDate);
        return Date.from(localDate.atStartOfDay(ZoneId.systemDefault()).toInstant());
    }
}
