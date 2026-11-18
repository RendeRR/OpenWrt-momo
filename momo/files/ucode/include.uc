import { readfile, writefile, popen } from 'fs';

const HOME_DIR = '/etc/momo';
const PROFILES_DIR = `${HOME_DIR}/profiles`;
const SUBSCRIPTIONS_DIR = `${HOME_DIR}/subscriptions`;
const RUN_DIR = `${HOME_DIR}/run`;
const RUN_PROFILE_PATH = `${RUN_DIR}/config.json`;
const UCODE_DIR = `${HOME_DIR}/ucode`;
const SH_DIR = `${HOME_DIR}/scripts`;
const FIREWALL_DIR = `${HOME_DIR}/firewall`;
const LOG_DIR = '/var/log/momo';
const TEMP_DIR = '/var/run/momo';

export const PATHS = {
	home_dir: HOME_DIR,
	profiles_dir: PROFILES_DIR,
	subscriptions_dir: SUBSCRIPTIONS_DIR,
	run_dir: RUN_DIR,
	run_profile_path: RUN_PROFILE_PATH,
	ucode_dir: UCODE_DIR,
	include_uc: `${UCODE_DIR}/include.uc`,
	hijack_ut: `${UCODE_DIR}/hijack.ut`,
	sh_dir: SH_DIR,
	include_sh: `${SH_DIR}/include.sh`,
	firewall_include_sh: `${SH_DIR}/firewall_include.sh`,
	debug_sh: `${SH_DIR}/debug.sh`,
	firewall_dir: FIREWALL_DIR,
	geoip_cn_nft: `${FIREWALL_DIR}/geoip_cn.nft`,
	geoip6_cn_nft: `${FIREWALL_DIR}/geoip6_cn.nft`,
	log_dir: LOG_DIR,
	app_log_path: `${LOG_DIR}/app.log`,
	core_log_path: `${LOG_DIR}/core.log`,
	debug_log_path: `${LOG_DIR}/debug.log`,
	temp_dir: TEMP_DIR,
	pid_file_path: `${TEMP_DIR}/momo.pid`,
	started_flag_path: `${TEMP_DIR}/started.flag`,
	bridge_nf_call_iptables_flag_path: `${TEMP_DIR}/bridge_nf_call_iptables.flag`,
	bridge_nf_call_ip6tables_flag_path: `${TEMP_DIR}/bridge_nf_call_ip6tables.flag`
};

export function get_paths() {
	return { ...PATHS };
};

export function uci_bool(obj) {
	return obj == null ? null : obj == '1';
};

export function uci_int(obj) {
	return obj == null ? null : int(obj);
};

export function uci_array(obj) {
	if (obj == null) {
		return [];
	}
	if (type(obj) == 'array') {
		return uniq(obj);
	}
	return [obj];
};

export function merge(target, ...sources) {
	for (let source in sources) {
		for (let key in keys(source)) {
			const target_value = target[key];
			const target_value_type = type(target_value);
			const source_value = source[key];
			const source_value_type = type(source_value);
			if (target_value_type === 'object' && source_value_type === 'object') {
				target[key] = merge(target_value, source_value);
			} else {
				target[key] = source[key];
			}
		}
	}
	return target;
};

export function merge_exists(target, ...sources) {
	for (let source in sources) {
		if (type(source) != 'object') {
			continue;
		}
		for (let key in keys(source)) {
			if (exists(target, key)) {
				const target_value = target[key];
				const target_value_type = type(target_value);
				const source_value = source[key];
				const source_value_type = type(source_value);
				if (target_value_type === 'object' && source_value_type === 'object') {
					target[key] = merge_exists(target_value, source_value);
				} else {
					target[key] = source[key];
				}
			}
		}
	}
	return target;
};

export function trim_all(obj) {
	if (obj == null) {
		return null;
	}
	if (type(obj) == 'string') {
		if (length(obj) == 0) {
			return null;
		}
		return obj;
	}
	if (type(obj) == 'array') {
		if (length(obj) == 0) {
			return null;
		}
		return obj;
	}
	if (type(obj) == 'object') {
		const obj_keys = keys(obj);
		for (let key in obj_keys) {
			obj[key] = trim_all(obj[key]);
			if (obj[key] == null) {
				delete obj[key];
			}
		}
		if (length(keys(obj)) == 0) {
			return null;
		}
		return obj;
	}
	return obj;
};

export function get_cgroups_version() {
	const mounts = readfile('/proc/mounts') ?? '';
	return (index(mounts, '\ncgroup ') >= 0 || substr(mounts, 0, 7) == 'cgroup ') ? 1 : 2;
};

export function get_users() {
	const passwd = readfile('/etc/passwd') ?? '';
	return map(split(passwd, '\n'), (x) => split(x, ':')[0]);
};

export function get_groups() {
	const group = readfile('/etc/group') ?? '';
	return map(split(group, '\n'), (x) => split(x, ':')[0]);
};

export function get_cgroups() {
	const result = [];
	if (get_cgroups_version() == 2) {
		const cgroup_path = '/sys/fs/cgroup/';
		const process = popen(`find ${cgroup_path} -type d -mindepth 1 2>/dev/null`);
		if (process) {
			for (let line = process.read('line'); length(line); line = process.read('line')) {
				push(result, substr(trim(line), length(cgroup_path)));
			}
			process.close();
		}
	}
	return result;
};

export function load_profile() {
	const content = readfile(PATHS.run_profile_path);
	if (!content) {
		return {};
	}
	try {
		return json(content) ?? {};
	} catch (e) {
		return {};
	}
};

export function save_profile(obj) {
	return writefile(PATHS.run_profile_path, obj);
};