package com.zion.os

import android.app.job.JobParameters
import android.app.job.JobService

class ZionJobService : JobService() {
    override fun onStartJob(params: JobParameters?): Boolean {
        params?.let { jobFinished(it, false) }
        return false
    }
    override fun onStopJob(params: JobParameters?): Boolean = false
}
