'use strict';
'require form';
'require view';
'require uci';
'require fs';
'require ui';
'require tools.momo as momo';

return view.extend({
    load: function () {
        return Promise.all([
            uci.load('momo'),
            momo.getPaths(),
            momo.listProfiles(),
        ]);
    },
    render: function (data) {
        const subscriptions = uci.sections('momo', 'subscription');
        const paths = data[1];
        const profiles = data[2];

        let m, s, o;

        m = new form.Map('momo');

        s = m.section(form.NamedSection, 'placeholder', 'placeholder', _('Editor'));

        o = s.option(form.ListValue, '_file', _('Choose File'));
        o.optional = true;

        for (const profile of profiles) {
            o.value(paths.profiles_dir + '/' + profile.name, _('File:') + profile.name);
        };

        for (const subscription of subscriptions) {
            o.value(paths.subscriptions_dir + '/' + subscription['.name'] + '.json', _('Subscription:') + subscription.name);
        };

        o.value(paths.run_profile_path, _('Profile for Startup'));

        o.write = function (section_id, formvalue) {
            return true;
        };
        o.onchange = function (event, section_id, value) {
            return L.resolveDefault(fs.read_direct(value), '').then(function (content) {
                m.lookupOption('_file_content', section_id)[0].getUIElement(section_id).setValue(content);
            });
        };

        o = s.option(form.DummyValue, '_editor_actions', _('Profile Tools'));
        o.renderWidget = function (section_id) {
            const tmpPath = '/tmp/momo_editor.json';

            const getEditorElement = function () {
                return m.lookupOption('_file_content', section_id)[0].getUIElement(section_id);
            };

            const cleanOutput = function (str) {
                return String(str || '')
                    .replace(/\x1b\[[0-9;]*[a-zA-Z]/g, '')
                    .replace(/\[[0-9;]+m/g, '')
                    .replace(/\[[0-9]{4}\]\s*/g, ': ')
                    .replace(/\s+at\s+\/tmp\/momo_editor\.json/g, '');
            };

            const checkBtn = E('button', {
                class: 'cbi-button cbi-button-action',
                style: 'margin-right: 8px;',
                click: function () {
                    const uiEl = getEditorElement();
                    const content = uiEl ? uiEl.getValue() : '';
                    if (!content || !content.trim()) {
                        ui.addNotification(null, E('p', _('Editor content is empty.')), 'warning');
                        return;
                    }
                    return momo.writefile(tmpPath, content).then(function () {
                        return momo.checkProfile(tmpPath);
                    }).then(function (res) {
                        const valid = res && res.valid;
                        const msg = (res && res.output) ? cleanOutput(res.output) : (valid ? _('Configuration is valid.') : _('Check failed.'));
                        ui.showModal(_('Sing-Box Profile Check'), [
                            E('pre', {
                                style: 'white-space: pre-wrap; font-weight: bold; color: ' + (valid ? 'green;' : 'red;')
                            }, msg),
                            E('div', { class: 'right' }, [
                                E('button', { class: 'btn', click: ui.hideModal }, _('Close'))
                            ])
                        ]);
                    });
                }
            }, _('Test Config (sing-box check)'));

            const formatBtn = E('button', {
                class: 'cbi-button cbi-button-positive',
                click: function () {
                    const uiEl = getEditorElement();
                    const content = uiEl ? uiEl.getValue() : '';
                    if (!content || !content.trim()) {
                        ui.addNotification(null, E('p', _('Editor content is empty.')), 'warning');
                        return;
                    }
                    return momo.writefile(tmpPath, content).then(function () {
                        return momo.formatProfile(tmpPath);
                    }).then(function (res) {
                        if (res && res.valid) {
                            return L.resolveDefault(fs.read_direct(tmpPath), '').then(function (formatted) {
                                if (formatted && uiEl) {
                                    uiEl.setValue(formatted);
                                }
                            });
                        } else {
                            const msg = (res && res.output) ? cleanOutput(res.output) : _('Format failed.');
                            ui.showModal(_('Sing-Box Format Failed'), [
                                E('pre', {
                                    style: 'white-space: pre-wrap; color: red;'
                                }, msg),
                                E('div', { class: 'right' }, [
                                    E('button', { class: 'btn', click: ui.hideModal }, _('Close'))
                                ])
                            ]);
                        }
                    });
                }
            }, _('Format JSON (sing-box format)'));

            return E('div', { style: 'display: flex; align-items: center; flex-wrap: wrap; gap: 6px;' }, [
                checkBtn,
                formatBtn
            ]);
        };

        o = s.option(form.TextValue, '_file_content',);
        o.rows = 25;
        o.wrap = false;
        o.write = function (section_id, formvalue) {
            const path = m.lookupOption('_file', section_id)[0].formvalue(section_id);
            return momo.writefile(path, formvalue);
        };
        o.remove = function (section_id) {
            const path = m.lookupOption('_file', section_id)[0].formvalue(section_id);
            return momo.writefile(path);
        };

        return m.render();
    },
    handleSaveApply: function (ev, mode) {
        return this.handleSave(ev).finally(function () {
            return mode === '0' ? momo.reload() : momo.restart();
        });
    },
    handleReset: null
});
