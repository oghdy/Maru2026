package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonAlias;

import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class StepDto {
    private String stepId;
    private Integer orderNum;
    
    @JsonAlias({"step_type", "stepType"})
    private String stepType;
    private String title;
    private String instruction;

    // Use contentObj to match the frontend and new unit0 format
    // mapped generically to allow any structure inside.
    @JsonAlias({"content", "contentObj"})
    private Map<String, Object> contentObj;

    // Keep legacy content map just in case for backward compatibility
    private Map<String, Object> content;
}
