package aeolus.mail.service;

import aeolus.mail.Attachment;
import aeolus.mail.Mail;
import common.inject.api.RegisterFor;
import common.logger.Logger;
import jakarta.activation.DataHandler;
import jakarta.activation.DataSource;
import jakarta.activation.FileDataSource;
import jakarta.mail.*;
import jakarta.mail.internet.*;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.Properties;
import java.util.UUID;

@RegisterFor(MailService.class)
public class MailService {
    private static final Logger LOGGER = new Logger(MailService.class);

    public void send(Mail mail) {
        Path tempDir = null;
        try {
            tempDir = Files.createTempDirectory("mail-" + UUID.randomUUID());
            final Message msg;
            if (mail.getAttachments().isEmpty()) {
                msg = buildSimpleMail(mail);
            } else {
                msg = buildMailWithAttachments(mail, tempDir);
            }
            LOGGER.debug("Sending email...");
            Transport.send(msg);
            LOGGER.debug("Email sent.");
        } catch (MessagingException | IOException e) {
            LOGGER.trace(e);
        } finally {
            cleanup(tempDir);
        }
    }

    private Message buildSimpleMail(Mail mail) throws MessagingException {
        final Message msg = constructMessage(mail);
        msg.setText(mail.getBody());
        return msg;
    }

    private Message buildMailWithAttachments(Mail mail, Path tempDir) throws MessagingException, IOException {
        final Message msg = constructMessage(mail);

        final MimeBodyPart textPart = new MimeBodyPart();
        textPart.setText(mail.getBody());


        Multipart multipart = new MimeMultipart();
        multipart.addBodyPart(textPart);

        for (Attachment file : mail.getAttachments()) {
            attacheFile(multipart, file, tempDir);
        }

        msg.setContent(multipart);
        return msg;
    }

    private void attacheFile(Multipart multipart, Attachment sFile, Path tempDir) throws MessagingException, IOException {
        final Path filePath = tempDir.resolve(sFile.getName());
        Files.write(filePath, sFile.getFile().getContent());
        final File file = new File(filePath.toAbsolutePath().toString());

        final MimeBodyPart filePart = new MimeBodyPart();

        final DataSource source = new FileDataSource(file);
        filePart.setDataHandler(new DataHandler(source));
        filePart.setFileName(file.getName());

        multipart.addBodyPart(filePart);
    }

    private Message constructMessage(Mail mail) throws MessagingException {
        LOGGER.debug("Preparing to send email to " + mail.getRecipient());
        final String smtpHost = "MAILSERVER";
        final String username = "SENDER";
        final String password = "PASSWORD";

        final Properties props = new Properties();
        props.put("mail.smtp.host", smtpHost);
        props.put("mail.smtp.port", "587");
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");

        LOGGER.debug("Creating email session...");

        final Session session = Session.getInstance(
                props,
                new Authenticator() {
                    protected PasswordAuthentication getPasswordAuthentication() {
                        return new PasswordAuthentication(username, password);
                    }
                }
        );

        LOGGER.debug("Composing email...");

        final Message msg = new MimeMessage(session);

        msg.setFrom(new InternetAddress(username));
        msg.setRecipients(
                Message.RecipientType.TO,
                InternetAddress.parse(mail.getRecipient())
        );

        msg.setSubject(mail.getSubject());
        return msg;
    }

    private static void cleanup(Path path) {
        if (path == null || !Files.exists(path)) return;

        try {
            Files.walk(path).sorted(Comparator.reverseOrder())
                    .forEach(p -> {
                        try {
                            Files.deleteIfExists(p);
                        } catch (IOException ignored) {
                        }
                    });
        } catch (IOException e) {
            LOGGER.trace(e);
        }
    }
}
