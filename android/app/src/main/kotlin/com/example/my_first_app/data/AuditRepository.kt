package com.example.my_first_app.data

import kotlinx.coroutines.flow.Flow

class AuditRepository(private val auditDao: AuditDao) {
    val allAudits: Flow<List<PropertyAudit>> = auditDao.getAllAudits()

    suspend fun getAuditById(id: String): PropertyAudit? {
        return auditDao.getAuditById(id)
    }

    suspend fun insertAudit(audit: PropertyAudit) {
        auditDao.insertAudit(audit)
    }

    suspend fun deleteAudit(id: String) {
        auditDao.deleteAuditById(id)
    }
}
