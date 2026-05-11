package com.doitdo.domain.bugreport.repository;

import com.doitdo.domain.bugreport.entity.BugReport;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BugReportRepository extends JpaRepository<BugReport, Long> {
}
