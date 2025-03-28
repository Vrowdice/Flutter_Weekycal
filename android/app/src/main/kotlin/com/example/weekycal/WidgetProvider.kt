package com.example.weekycal

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.NonNull
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONException

class AppWidgetProvider : HomeWidgetProvider() {

companion object {
    private const val SCHEDULE_DATA_KEY = "schedule_data"
    val TV_SCHEDULE_NAME_1 = R.id.tv_schedule_name_1
    val TV_SCHEDULE_NAME_2 = R.id.tv_schedule_name_2
    val TV_SCHEDULE_NAME_3 = R.id.tv_schedule_name_3
    val TV_SCHEDULE_NAME_4 = R.id.tv_schedule_name_4
    val TV_SCHEDULE_NAME_5 = R.id.tv_schedule_name_5
    val TV_SCHEDULE_NAME_6 = R.id.tv_schedule_name_6
    val TV_SCHEDULE_NAME_7 = R.id.tv_schedule_name_7

}

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            val scheduleJson = widgetData.getString(SCHEDULE_DATA_KEY, "[]") ?: "[]"
            val weekList = parseScheduleData(scheduleJson)
            
            for (dayIndex in 0 until 7) {
                val daySchedule = weekList.getOrNull(dayIndex)
                
                if (daySchedule != null && daySchedule.schedules.isNotEmpty()) {
                    var text = "\n "
                    
                    for (schedule in daySchedule.schedules) {
                        text += "${schedule.name}\n"
                        
                        val startTimeFormatted = convertMinutesToTime(schedule.startTime)
                        val endTimeFormatted = convertMinutesToTime(schedule.endTime)
                        
                        text += "$startTimeFormatted ~ $endTimeFormatted\n"
                    }
                    
                    views.setTextViewText(getScheduleNameViewId(dayIndex), text.trim())
                    views.setViewVisibility(getScheduleNameViewId(dayIndex), View.VISIBLE)
                } else {
                    views.setViewVisibility(getScheduleNameViewId(dayIndex), View.GONE)
                }
            }

            val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("myAppWidget://refreshSchedule")
            )
            views.setOnClickPendingIntent(R.id.bt_update, refreshIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.data?.toString() == "myAppWidget://refreshSchedule") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, AppWidgetProvider::class.java)
            )
            onUpdate(context, appWidgetManager, widgetIds,
                context.getSharedPreferences("widget_data", Context.MODE_PRIVATE))
        }
    }

    // JSON to ScheduleData list
    private fun parseScheduleData(jsonString: String): List<ScheduleData> {
        val scheduleList = mutableListOf<ScheduleData>()
        try {
            val jsonArray = JSONArray(jsonString)

            for (i in 0 until jsonArray.length()) {
                val jsonObject = jsonArray.getJSONObject(i)

                val scheduleInfoArray = jsonObject.getJSONArray("scheduleInfo")
                val schedules = mutableListOf<Schedule>()

                for (j in 0 until scheduleInfoArray.length()) {
                    val scheduleInfo = scheduleInfoArray.getJSONObject(j)
                    val schedule = Schedule(
                        scheduleInfo.getString("name"),
                        scheduleInfo.getInt("startTime"),
                        scheduleInfo.getInt("endTime")
                    )
                    schedules.add(schedule)
                }

                // make ScheduleData class
                val scheduleData = ScheduleData(schedules)
                scheduleList.add(scheduleData)
            }
        } catch (e: JSONException) {
            Log.e("AppWidgetProvider", "Error parsing JSON: ${e.message}")
            // Handle the error appropriately, e.g., return an empty list or display an error message
        }
        return scheduleList
    }

    data class ScheduleData(
        val schedules: List<Schedule> = emptyList()
    )

    data class Schedule(
        val name: String,
        val startTime: Int,
        val endTime: Int,
    )

    private fun getScheduleNameViewId(index: Int): Int {
        return when (index) {
            0 -> TV_SCHEDULE_NAME_1
            1 -> TV_SCHEDULE_NAME_2
            2 -> TV_SCHEDULE_NAME_3
            3 -> TV_SCHEDULE_NAME_4
            4 -> TV_SCHEDULE_NAME_5
            5 -> TV_SCHEDULE_NAME_6
            else -> TV_SCHEDULE_NAME_7
        }
    }

    fun convertMinutesToTime(minutes: Int): String {
        val hours = minutes / 60
        val mins = minutes % 60
        return String.format("%02d:%02d", hours, mins)
    }            
}