package com.example.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
public class TestController {

    private static final Logger logger = LoggerFactory.getLogger(TestController.class);
    private final UserRepository userRepository;

    public TestController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/test-trace")
    public List<User> triggerTrace() {
        logger.info("Starting trace request using JDBC Template");

        // This call will be automatically instrumented by the OTel agent
        // You will see a span named "SELECT users" in Jaeger
        List<User> users = userRepository.findAll();

        logger.info("Retrieved {} users", users.size());
        return users;
    }
}