'use strict';
'require form';
'require view';
'require uci';
'require fs';
'require poll';
'require tools.momo as momo';

function updateLogTextarea(uiElement, newContent) {
    if (!uiElement || !uiElement.node) return;
    const textarea = uiElement.node.querySelector('textarea') || uiElement.node.firstChild;
    if (!textarea) {
        uiElement.setValue(newContent);
        return;
    }
    const prevScrollTop = textarea.scrollTop;
    const wasAtBottom = (textarea.scrollHeight - textarea.clientHeight - prevScrollTop) <= 24;
    uiElement.setValue(newContent);
    if (wasAtBottom) {
        textarea.scrollTop = textarea.scrollHeight;
    } else {
        textarea.scrollTop = prevScrollTop;
    }
}

return view.extend({
    load: function () {
        return Promise.all([
            uci.load('momo'),
            momo.getPaths(),
            momo.getLogStat('app'),
            momo.getLogStat('core')
        ]);
    },
    render: function (data) {
        const paths = data[1];
        const appLogInit = data[2] || { content: '', size: 0, mtime: 0 };
        const coreLogInit = data[3] || { content: '', size: 0, mtime: 0 };

        const logState = {
            app: { size: appLogInit.size, mtime: appLogInit.mtime },
            core: { size: coreLogInit.size, mtime: coreLogInit.mtime }
        };

        let m, s, o, appLogOpt, coreLogOpt;

        m = new form.Map('momo');

        s = m.section(form.NamedSection, 'log', 'log', _('Log'));

        s.tab('log_config', _('Log Config'));

        o = s.taboption('log_config', form.Flag, 'clear_at_stop', _('Clear At Stop'));
        o.rmempty = false;

        o = s.taboption('log_config', form.Flag, 'scheduled_clear', _('Scheduled Clear'));
        o.rmempty = false;

        o = s.taboption('log_config', form.Value, 'scheduled_clear_cron', _('Scheduled Clear Cron'));
        o.retain = true;
        o.rmempty = false;
        o.depends('scheduled_clear', '1');

        o = s.taboption('log_config', form.Value, 'scheduled_clear_size_limit', _('Scheduled Clear Size Limit'));
        o.retain = true;
        o.rmempty = false;
        o.datatype = 'uinteger';
        o.depends('scheduled_clear', '1');

        o = s.taboption('log_config', form.ListValue, 'scheduled_clear_size_limit_unit', _('Scheduled Clear Size Limit Unit'));
        o.retain = true;
        o.rmempty = false;
        o.depends('scheduled_clear', '1');
        o.value('B', 'B');
        o.value('KB', 'KB');
        o.value('MB', 'MB');
        o.value('GB', 'GB');

        s.tab('app_log', _('App Log'));

        o = s.taboption('app_log', form.Button, 'clear_app_log');
        o.inputstyle = 'negative';
        o.inputtitle = _('Clear Log');
        o.onclick = function (_, section_id) {
            logState.app = { size: 0, mtime: 0 };
            m.lookupOption('_app_log', section_id)?.[0]?.getUIElement(section_id)?.setValue('');
            return momo.clearAppLog();
        };

        appLogOpt = s.taboption('app_log', form.TextValue, '_app_log');
        appLogOpt.rows = 25;
        appLogOpt.wrap = false;
        appLogOpt.load = function () {
            return appLogInit.content;
        };
        appLogOpt.write = function () {
            return true;
        };

        o = s.taboption('app_log', form.Button, 'scroll_app_log_to_bottom');
        o.inputtitle = _('Scroll To Bottom');
        o.onclick = function (_, section_id) {
            const uiEl = m.lookupOption('_app_log', section_id)?.[0]?.getUIElement(section_id);
            const element = uiEl?.node?.querySelector('textarea') || uiEl?.node?.firstChild;
            if (element) element.scrollTop = element.scrollHeight;
        };

        s.tab('core_log', _('Core Log'));

        o = s.taboption('core_log', form.Button, 'clear_core_log');
        o.inputstyle = 'negative';
        o.inputtitle = _('Clear Log');
        o.onclick = function (_, section_id) {
            logState.core = { size: 0, mtime: 0 };
            m.lookupOption('_core_log', section_id)?.[0]?.getUIElement(section_id)?.setValue('');
            return momo.clearCoreLog();
        };

        coreLogOpt = s.taboption('core_log', form.TextValue, '_core_log');
        coreLogOpt.rows = 25;
        coreLogOpt.wrap = false;
        coreLogOpt.load = function () {
            return coreLogInit.content;
        };
        coreLogOpt.write = function () {
            return true;
        };

        o = s.taboption('core_log', form.Button, 'scroll_core_log_to_bottom');
        o.inputtitle = _('Scroll To Bottom');
        o.onclick = function (_, section_id) {
            const uiEl = m.lookupOption('_core_log', section_id)?.[0]?.getUIElement(section_id);
            const element = uiEl?.node?.querySelector('textarea') || uiEl?.node?.firstChild;
            if (element) element.scrollTop = element.scrollHeight;
        };

        s.tab('debug_log', _('Debug Log'));

        o = s.taboption('debug_log', form.Button, '_generate_download_debug_log');
        o.inputstyle = 'negative';
        o.inputtitle = _('Generate & Download');
        o.onclick = function () {
            return momo.debug().then(function () {
                return fs.read_direct(paths.debug_log_path, 'blob').then(function (data) {
                    const url = window.URL.createObjectURL(data, { type: 'text/markdown' });
                    const link = document.createElement('a');
                    link.href = url;
                    link.download = 'debug.log';
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                    window.URL.revokeObjectURL(url);
                });
            });
        };

        return m.render().then(function (mapEl) {
            poll.add(function () {
                if (!m.root) return Promise.resolve();

                const tasks = [];
                const appUi = appLogOpt.getUIElement('log');
                const coreUi = coreLogOpt.getUIElement('log');

                if (appUi?.node?.offsetParent) {
                    tasks.push(momo.getLogStat('app').then(function (res) {
                        if (res && (res.size !== logState.app.size || res.mtime !== logState.app.mtime)) {
                            logState.app = { size: res.size, mtime: res.mtime };
                            updateLogTextarea(appUi, res.content ?? '');
                        }
                    }));
                }

                if (coreUi?.node?.offsetParent) {
                    tasks.push(momo.getLogStat('core').then(function (res) {
                        if (res && (res.size !== logState.core.size || res.mtime !== logState.core.mtime)) {
                            logState.core = { size: res.size, mtime: res.mtime };
                            updateLogTextarea(coreUi, res.content ?? '');
                        }
                    }));
                }

                return Promise.all(tasks);
            });

            return mapEl;
        });
    }
});
