package com.smartmarket.hrm.auth;

public record CurrentUser(
        Long employeeId,
        String employeeCode,
        String fullName,
        String email,
        String roleCode,
        String roleName,
        Long branchId) { }
