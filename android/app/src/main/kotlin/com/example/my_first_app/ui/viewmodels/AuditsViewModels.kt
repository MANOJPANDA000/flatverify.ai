package com.example.my_first_app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.my_first_app.data.AuditRepository
import com.example.my_first_app.data.PropertyAudit
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class HomeViewModel(private val repository: AuditRepository) : ViewModel() {
    val recentAudits: StateFlow<List<PropertyAudit>> = repository.allAudits
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )
}

class HistoryViewModel(private val repository: AuditRepository) : ViewModel() {
    val allAudits: StateFlow<List<PropertyAudit>> = repository.allAudits
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    fun deleteAudit(id: String) {
        viewModelScope.launch {
            repository.deleteAudit(id)
        }
    }
}
