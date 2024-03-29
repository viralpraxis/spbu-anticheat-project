package ru.spbu.detector.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import ru.spbu.detector.client.config.FrontierClientConfig;
import ru.spbu.detector.dto.SubmissionStatusDto;

@FeignClient(
        name = "frontier-api",
        url = "${client.frontier.url}",
        configuration = FrontierClientConfig.class
)
public interface FrontierClient {
    @PutMapping(value = "{resultPath}", produces = MediaType.APPLICATION_JSON_VALUE)
    void setSubmissionStatus(@PathVariable("resultPath") String resultPath, @RequestBody SubmissionStatusDto status);
}
