package com.d107.doitdo.widget

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.d107.doitdo.R

/**
 * 현재 미사용 (DoitdoWidgetProvider 가 고정 4행 방식으로 전환).
 * RemoteViewsService 기반 ListView 어댑터 — 추후 필요 시 활성화.
 */
class TodoListService : RemoteViewsService() {
    companion object {
        const val EXTRA_LIST_TYPE = "listType"
        const val TYPE_TODAY = "today"
        const val TYPE_SOMEDAY = "someday"
    }

    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TodoListFactory(applicationContext, intent)
}

private class TodoListFactory(
    private val context: Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {

    private val listType = intent.getStringExtra(TodoListService.EXTRA_LIST_TYPE)
    private var items: List<WidgetTodo> = emptyList()

    override fun onCreate() = loadData()
    override fun onDataSetChanged() = loadData()
    override fun onDestroy() {}

    private fun loadData() {
        val payload = WidgetSharedStore.payload(context)
        val all = when (listType) {
            TodoListService.TYPE_TODAY -> payload?.todayTodos.orEmpty()
            else -> payload?.somedayTodos.orEmpty()
        }
        items = all.filter { !it.isDone }
    }

    override fun getCount() = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val todo = items.getOrNull(position)
            ?: return RemoteViews(context.packageName, R.layout.widget_todo_item)
        val rv = RemoteViews(context.packageName, R.layout.widget_todo_item)
        rv.setImageViewResource(R.id.item_check, R.drawable.widget_check_inactive)
        rv.setTextViewText(R.id.item_title, todo.title)
        rv.setTextColor(R.id.item_title, context.getColor(R.color.widget_text_primary))
        val fillIn = Intent().apply { putExtra(ToggleTodoReceiver.EXTRA_TODO_ID, todo.id) }
        rv.setOnClickFillInIntent(R.id.item_check, fillIn)
        return rv
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount() = 1
    override fun getItemId(position: Int) = items.getOrNull(position)?.id?.toLong() ?: position.toLong()
    override fun hasStableIds() = true
}
