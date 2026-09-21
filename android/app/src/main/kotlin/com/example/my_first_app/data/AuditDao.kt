package com.example.my_first_app.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface AuditDao {
    @Query("SELECT * FROM audits ORDER BY timestamp DESC")
    fun getAllAudits(): Flow<List<PropertyAudit>>

    @Query("SELECT * FROM audits WHERE id = :id")
    suspend fun getAuditById(id: String): PropertyAudit?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAudit(audit: PropertyAudit)

    @Delete
    suspend fun deleteAudit(audit: PropertyAudit)

    @Query("DELETE FROM audits WHERE id = :id")
    suspend fun deleteAuditById(id: String)
}
