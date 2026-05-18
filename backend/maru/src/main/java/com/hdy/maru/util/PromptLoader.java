package com.hdy.maru.util;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Component
public class PromptLoader {

    /**
     * Loads a prompt template from the classpath (resources/prompts/) and replaces
     * {{variable}} placeholders with values from the provided map.
     *
     * @param fileName  the filename under resources/prompts/ (e.g., "mission_setup_system.txt")
     * @param variables map of variable name → replacement value
     * @return the processed prompt string
     */
    public String load(String fileName, Map<String, String> variables) {
        String template = loadRaw(fileName);
        return replacePlaceholders(template, variables);
    }

    /**
     * Loads a prompt template without variable substitution.
     */
    public String loadRaw(String fileName) {
        try {
            ClassPathResource resource = new ClassPathResource("prompts/" + fileName);
            byte[] bytes = resource.getInputStream().readAllBytes();
            return new String(bytes, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException("Failed to load prompt file: " + fileName, e);
        }
    }

    private String replacePlaceholders(String template, Map<String, String> variables) {
        if (variables == null || variables.isEmpty()) {
            return template;
        }
        String result = template;
        for (Map.Entry<String, String> entry : variables.entrySet()) {
            String placeholder = "{{" + entry.getKey() + "}}";
            String value = entry.getValue() != null ? entry.getValue() : "";
            result = result.replace(placeholder, value);
        }
        return result;
    }
}
