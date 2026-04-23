package com.aihealthappoffline.android.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.HealthAppApplication
import com.aihealthappoffline.android.data.models.PeriodEntry
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class PeriodTrackingViewModel(application: Application) : AndroidViewModel(application) {

    private val periodEntryDao = HealthAppApplication.database.periodEntryDao()

    private val _entries = MutableStateFlow<List<PeriodEntry>>(emptyList())
    val entries: StateFlow<List<PeriodEntry>> = _entries.asStateFlow()

    private val today: String = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

    init {
        viewModelScope.launch {
            periodEntryDao.getAllEntries().collect { _entries.value = it }
        }
    }

    fun addEntry(flowLevel: Int, symptoms: String? = null, notes: String? = null) {
        viewModelScope.launch {
            val entry = PeriodEntry(
                startDate = today,
                flowLevel = flowLevel,
                symptoms = symptoms,
                notes = notes
            )
            periodEntryDao.insert(entry)
        }
    }

    fun deleteEntry(id: Long) {
        viewModelScope.launch {
            periodEntryDao.deleteById(id)
        }
    }
}