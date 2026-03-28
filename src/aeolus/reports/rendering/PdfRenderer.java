package aeolus.reports.rendering;

import common.inject.api.RegisterFor;
import dobby.files.StaticFile;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.UUID;

@RegisterFor(PdfRenderer.class)
public class PdfRenderer {
    private static void deleteQuietly(Path path) {
        if (path == null || !Files.exists(path)) return;

        try {
            Files.walk(path).sorted(Comparator.reverseOrder())
                    .forEach(p -> {
                        try {
                            Files.deleteIfExists(p);
                        } catch (IOException ignored) {
                        }
                    });
        } catch (IOException ignored) {
        }
    }

    public StaticFile render(StaticFile file) {
        Path tempDir = null;
        try {
            tempDir = Files.createTempDirectory("typst-" + UUID.randomUUID());
            Path inputFile = tempDir.resolve("input.typ");
            Path outputFile = tempDir.resolve("output.pdf");
            Files.write(inputFile, file.getContent());

            ProcessBuilder processBuilder = new ProcessBuilder("typst", "compile", inputFile.toAbsolutePath().toString(), outputFile.toAbsolutePath().toString());

            processBuilder.redirectErrorStream(true);
            Process process = processBuilder.start();

            String processOutput;
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {

                StringBuilder outputBuilder = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    outputBuilder.append(line).append("\n");
                }
                processOutput = outputBuilder.toString();
            }

            int exitCode = process.waitFor();

            if (exitCode != 0) {
                throw new RuntimeException("Typst compilation failed:\n" + processOutput);
            }

            if (!Files.exists(outputFile)) {
                throw new FileNotFoundException("Output PDF was not created.");
            }

            final StaticFile pdfFile = new StaticFile();
            pdfFile.setContent(Files.readAllBytes(outputFile));
            pdfFile.setContentType("application/pdf");
            return pdfFile;

        } catch (InterruptedException | IOException e) {
            throw new RuntimeException(e);
        } finally {
            deleteQuietly(tempDir);
        }
    }
}
