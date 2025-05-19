package com.example.pocspringboot.service;

import org.springframework.stereotype.Service;

@Service
public class HelloService {

    public String getHelloWorld() {
        return "Hello World";
    }
} 