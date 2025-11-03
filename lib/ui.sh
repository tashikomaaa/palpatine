#!/bin/bash
# Palapatine - Open Source Project
# Copyright (C) 2025  Moutarlier Aldwin aka (tashikomaaa or corvus)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

#!/usr/bin/env bash
# lib/ui.sh
# UI helpers and simple i18n (L function).
# All comments in English.

# Application identity
APP_NAME="${APP_NAME:-PALPATINE}"
TAGLINE="${TAGLINE:-Galactic Server Control}"
if [[ -z "${VERSION:-}" ]]; then
  if [[ -f "$BASE_DIR/VERSION" ]]; then
    VERSION="$(<"$BASE_DIR/VERSION")"
  else
    VERSION="v0"
  fi
fi

# Language (UI_LANG) may be set via config; default to 'fr' for historical reasons
UI_LANG="${UI_LANG:-fr}"

# Color palette - Retro 16-color scheme (ANSI standard)
COL_RESET=$'\e[0m'
COL_HEADER=$'\e[1;36m'       # bright cyan (bold)
COL_SUB=$'\e[0;37m'          # white
COL_INFO=$'\e[0;36m'         # cyan
COL_OK=$'\e[0;32m'           # green
COL_WARN=$'\e[0;33m'         # yellow
COL_ERR=$'\e[0;31m'          # red
COL_MENU=$'\e[1;37m'         # bold white
COL_FRAME=$'\e[0;37m'        # white
COL_MUTED=$'\e[0;90m'        # dark gray

# Localization overrides for additional languages
declare -A L_RU=(
  [tagline]="Галактическое управление серверами"
  [quote]="«Пусть SSH течёт в вас.»"
  [cfg_active]="Активная конфигурация:"
  [cfg_group]="Группа"
  [cfg_user]="Пользователь"
  [cfg_jobs]="Загруженные системы"
  [cfg_timeout]="Тайм-аут"
  [menu.scan]="Сканировать системы (ping + uptime)"
  [menu.run]="Выполнить приказ"
  [menu.reboot]="Перезагрузить флот"
  [menu.shutdown]="Выключить флот"
  [menu.focus]="Управлять системой (фокус)"
  [menu.plugins]="Открыть отсек плагинов"
  [menu.add_server]="Добавить сервер"
  [menu.remove_server]="Удалить сервер"
  [menu.back]="Назад"
  [menu.quit]="Покинуть Империю"
  [prompt.choice]="Выбор (или буква: s=scan, r=reboot, q=quit):"
  [prompt.choice_short]="Выбор:"
  [prompt.enter]="[Нажмите Enter, чтобы продолжить]"
  [prompt.confirm]="Подтвердить? Введите Y для подтверждения:"
  [prompt.retry_interactive]="Повторить в интерактивном режиме? [y/N]:"
  [prompt.password_q]="Требуется пароль для"
  [prompt.add_server]="Сервер для добавления (user@host):"
  [prompt.remove_server]="Сервер для удаления (номер или host):"
  [empire.scan]="Сканирование флота..."
  [empire.deploy]="Выполнение приказа:"
  [empire.completed]="Сканирование завершено."
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping не удался для"
  [focus.title]="Фокус"
  [focus.status_label]="Статус"
  [focus.status_online]="в сети"
  [focus.status_offline]="не в сети"
  [focus.menu.uptime]="Показать uptime"
  [focus.menu.run]="Выполнить команду"
  [focus.menu.reboot]="Перезагрузить"
  [focus.menu.shutdown]="Выключить"
  [focus.menu.ssh]="Открыть интерактивный SSH"
  [focus.menu.back]="Вернуться к флоту"
  [focus.prompt.command]="Команда для выполнения:"
  [focus.prompt.select]="Номер или хост (например 2 или root@web-01):"
  [focus.systems_available]="Доступные системы:"
  [plugins.title]="Отсек плагинов"
  [plugins.prompt.choice]="Выберите плагин (0 чтобы вернуться):"
  [plugins.none]="Плагины не загружены."
  [msg.no_servers]="Серверы не найдены."
  [alert.invalid]="Недопустимый выбор."
  [alert.cancel]="Операция отменена."
  [victory.farewell]="Империя салютует вам."
)

declare -A L_DE=(
  [tagline]="Galaktische Serververwaltung"
  [quote]="\"Gut ... lass den SSH durch dich fließen.\""
  [cfg_active]="Aktive Konfiguration:"
  [cfg_group]="Gruppe"
  [cfg_user]="Benutzer"
  [cfg_jobs]="Geladene Systeme"
  [cfg_timeout]="Zeitlimit"
  [menu.scan]="Systeme scannen (Ping + Uptime)"
  [menu.run]="Befehl ausführen"
  [menu.reboot]="Flotte neu starten"
  [menu.shutdown]="Flotte herunterfahren"
  [menu.focus]="System steuern (Focus)"
  [menu.plugins]="Plugin-Hangar öffnen"
  [menu.add_server]="Server hinzufügen"
  [menu.remove_server]="Server entfernen"
  [menu.back]="Zurück"
  [menu.quit]="Das Imperium verlassen"
  [prompt.choice]="Auswahl (oder Buchstabe: s=scan, r=reboot, q=quit):"
  [prompt.choice_short]="Auswahl:"
  [prompt.enter]="[Drücken Sie Enter, um fortzufahren]"
  [prompt.confirm]="Bestätigen? Geben Sie Y zur Bestätigung ein:"
  [prompt.retry_interactive]="Interaktiv erneut versuchen? [y/N]:"
  [prompt.password_q]="Passwort erforderlich für"
  [prompt.add_server]="Server zum Hinzufügen (user@host):"
  [prompt.remove_server]="Server zum Entfernen (Nummer oder Host):"
  [empire.scan]="Flotte wird gescannt..."
  [empire.deploy]="Befehl wird ausgeführt:"
  [empire.completed]="Scan abgeschlossen."
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping fehlgeschlagen für"
  [focus.title]="Focus"
  [focus.status_label]="Status"
  [focus.status_online]="online"
  [focus.status_offline]="offline"
  [focus.menu.uptime]="Uptime anzeigen"
  [focus.menu.run]="Befehl ausführen"
  [focus.menu.reboot]="Neu starten"
  [focus.menu.shutdown]="Herunterfahren"
  [focus.menu.ssh]="Interaktives SSH öffnen"
  [focus.menu.back]="Zur Flotte zurückkehren"
  [focus.prompt.command]="Auszuführender Befehl:"
  [focus.prompt.select]="Nummer oder Host (z. B. 2 oder root@web-01):"
  [focus.systems_available]="Verfügbare Systeme:"
  [plugins.title]="Plugin-Hangar"
  [plugins.prompt.choice]="Plugin wählen (0 zum Zurückkehren):"
  [plugins.none]="Keine Plugins geladen."
  [msg.no_servers]="Keine Server gefunden."
  [alert.invalid]="Ungültige Auswahl."
  [alert.cancel]="Vorgang abgebrochen."
  [victory.farewell]="Das Imperium salutiert."
)

declare -A L_ES=(
  [tagline]="Control Galáctico de Servidores"
  [quote]="\"Bien... deja que el SSH fluya a través de ti.\""
  [cfg_active]="Configuración activa:"
  [cfg_group]="Grupo"
  [cfg_user]="Usuario"
  [cfg_jobs]="Sistemas cargados"
  [cfg_timeout]="Tiempo de espera"
  [menu.scan]="Escanear sistemas (ping + uptime)"
  [menu.run]="Ejecutar una orden"
  [menu.reboot]="Reiniciar la flota"
  [menu.shutdown]="Apagar la flota"
  [menu.focus]="Controlar un sistema (focus)"
  [menu.plugins]="Abrir la bahía de complementos"
  [menu.add_server]="Agregar un servidor"
  [menu.remove_server]="Eliminar un servidor"
  [menu.back]="Regresar"
  [menu.quit]="Salir del Imperio"
  [prompt.choice]="Elección (o letra: s=scan, r=reboot, q=quit):"
  [prompt.choice_short]="Elección:"
  [prompt.enter]="[Pulsa Enter para continuar]"
  [prompt.confirm]="¿Confirmar? Escribe Y para confirmar:"
  [prompt.retry_interactive]="¿Reintentar en modo interactivo? [y/N]:"
  [prompt.password_q]="Se requiere contraseña para"
  [prompt.add_server]="Servidor a agregar (usuario@host):"
  [prompt.remove_server]="Servidor a eliminar (número o host):"
  [empire.scan]="Escaneando la flota..."
  [empire.deploy]="Desplegando la orden:"
  [empire.completed]="Escaneo finalizado."
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping falló para"
  [focus.title]="Foco"
  [focus.status_label]="Estado"
  [focus.status_online]="en línea"
  [focus.status_offline]="fuera de línea"
  [focus.menu.uptime]="Consultar uptime"
  [focus.menu.run]="Ejecutar comando"
  [focus.menu.reboot]="Reiniciar"
  [focus.menu.shutdown]="Apagar"
  [focus.menu.ssh]="Abrir SSH interactivo"
  [focus.menu.back]="Volver a la flota"
  [focus.prompt.command]="Comando a ejecutar:"
  [focus.prompt.select]="Número u host (ej. 2 o root@web-01):"
  [focus.systems_available]="Sistemas disponibles:"
  [plugins.title]="Bahía de complementos"
  [plugins.prompt.choice]="Elige un complemento (0 para volver):"
  [plugins.none]="No hay complementos cargados."
  [msg.no_servers]="No se encontraron servidores."
  [alert.invalid]="Selección inválida."
  [alert.cancel]="Operación cancelada."
  [victory.farewell]="El Imperio te saluda."
)

declare -A L_PT=(
  [tagline]="Controle Galáctico de Servidores"
  [quote]="\"Muito bem... deixe o SSH fluir através de você.\""
  [cfg_active]="Configuração ativa:"
  [cfg_group]="Grupo"
  [cfg_user]="Usuário"
  [cfg_jobs]="Sistemas carregados"
  [cfg_timeout]="Tempo limite"
  [menu.scan]="Verificar sistemas (ping + uptime)"
  [menu.run]="Executar uma ordem"
  [menu.reboot]="Reiniciar a frota"
  [menu.shutdown]="Desligar a frota"
  [menu.focus]="Controlar um sistema (focus)"
  [menu.plugins]="Abrir o hangar de plugins"
  [menu.add_server]="Adicionar servidor"
  [menu.remove_server]="Remover servidor"
  [menu.back]="Voltar"
  [menu.quit]="Sair do Império"
  [prompt.choice]="Escolha (ou letra: s=scan, r=reboot, q=quit):"
  [prompt.choice_short]="Escolha:"
  [prompt.enter]="[Pressione Enter para continuar]"
  [prompt.confirm]="Confirmar? Digite Y para confirmar:"
  [prompt.retry_interactive]="Tentar novamente em modo interativo? [y/N]:"
  [prompt.password_q]="Senha necessária para"
  [prompt.add_server]="Servidor para adicionar (user@host):"
  [prompt.remove_server]="Servidor para remover (número ou host):"
  [empire.scan]="Escaneando a frota..."
  [empire.deploy]="Executando a ordem:"
  [empire.completed]="Verificação concluída."
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping falhou para"
  [focus.title]="Focus"
  [focus.status_label]="Status"
  [focus.status_online]="online"
  [focus.status_offline]="offline"
  [focus.menu.uptime]="Ver uptime"
  [focus.menu.run]="Executar comando"
  [focus.menu.reboot]="Reiniciar"
  [focus.menu.shutdown]="Desligar"
  [focus.menu.ssh]="Abrir SSH interativo"
  [focus.menu.back]="Voltar à frota"
  [focus.prompt.command]="Comando a executar:"
  [focus.prompt.select]="Número ou host (ex.: 2 ou root@web-01):"
  [focus.systems_available]="Sistemas disponíveis:"
  [plugins.title]="Hangar de plugins"
  [plugins.prompt.choice]="Escolha um plugin (0 para voltar):"
  [plugins.none]="Nenhum plugin carregado."
  [msg.no_servers]="Nenhum servidor encontrado."
  [alert.invalid]="Escolha inválida."
  [alert.cancel]="Operação cancelada."
  [victory.farewell]="O Império saúda você."
)

declare -A L_IT=(
  [tagline]="Controllo Galattico dei Server"
  [quote]="\"Bene... lascia che l'SSH scorra dentro di te.\""
  [cfg_active]="Configurazione attiva:"
  [cfg_group]="Gruppo"
  [cfg_user]="Utente"
  [cfg_jobs]="Sistemi caricati"
  [cfg_timeout]="Timeout"
  [menu.scan]="Scansione dei sistemi (ping + uptime)"
  [menu.run]="Eseguire un ordine"
  [menu.reboot]="Riavviare la flotta"
  [menu.shutdown]="Spegnere la flotta"
  [menu.focus]="Controllare un sistema (focus)"
  [menu.plugins]="Aprire l'hangar dei plugin"
  [menu.add_server]="Aggiungi server"
  [menu.remove_server]="Rimuovi server"
  [menu.back]="Torna indietro"
  [menu.quit]="Lascia l'Impero"
  [prompt.choice]="Scelta (o lettera: s=scan, r=reboot, q=quit):"
  [prompt.choice_short]="Scelta:"
  [prompt.enter]="[Premi Invio per continuare]"
  [prompt.confirm]="Confermare? Digita Y per confermare:"
  [prompt.retry_interactive]="Riprovare in modo interattivo? [y/N]:"
  [prompt.password_q]="Password richiesta per"
  [prompt.add_server]="Server da aggiungere (user@host):"
  [prompt.remove_server]="Server da rimuovere (numero o host):"
  [empire.scan]="Scansione della flotta..."
  [empire.deploy]="Esecuzione dell'ordine:"
  [empire.completed]="Scansione completata."
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping non riuscito per"
  [focus.title]="Focus"
  [focus.status_label]="Stato"
  [focus.status_online]="online"
  [focus.status_offline]="offline"
  [focus.menu.uptime]="Mostra uptime"
  [focus.menu.run]="Esegui comando"
  [focus.menu.reboot]="Riavvia"
  [focus.menu.shutdown]="Spegni"
  [focus.menu.ssh]="Apri SSH interattivo"
  [focus.menu.back]="Torna alla flotta"
  [focus.prompt.command]="Comando da eseguire:"
  [focus.prompt.select]="Numero o host (es. 2 o root@web-01):"
  [focus.systems_available]="Sistemi disponibili:"
  [plugins.title]="Hangar dei plugin"
  [plugins.prompt.choice]="Seleziona un plugin (0 per tornare):"
  [plugins.none]="Nessun plugin caricato."
  [msg.no_servers]="Nessun server trovato."
  [alert.invalid]="Scelta non valida."
  [alert.cancel]="Operazione annullata."
  [victory.farewell]="L'Impero ti saluta."
)

declare -A L_JA=(
  [tagline]="銀河サーバーコントロール"
  [quote]="「いいだろう…SSH に身を委ねなさい。」"
  [cfg_active]="有効な構成:"
  [cfg_group]="グループ"
  [cfg_user]="ユーザー"
  [cfg_jobs]="読み込まれたシステム"
  [cfg_timeout]="タイムアウト"
  [menu.scan]="システムをスキャン (ping + uptime)"
  [menu.run]="命令を実行"
  [menu.reboot]="艦隊を再起動"
  [menu.shutdown]="艦隊を停止"
  [menu.focus]="システムを制御 (フォーカス)"
  [menu.plugins]="プラグインハンガーを開く"
  [menu.add_server]="サーバーを追加"
  [menu.remove_server]="サーバーを削除"
  [menu.back]="戻る"
  [menu.quit]="帝国を去る"
  [prompt.choice]="選択 (または文字: s=scan, r=reboot, q=quit):"
  [prompt.choice_short]="選択:"
  [prompt.enter]="[Enter を押して続行]"
  [prompt.confirm]="確認しますか? 確認するには Y を入力:"
  [prompt.retry_interactive]="対話モードで再試行しますか? [y/N]:"
  [prompt.password_q]="次の操作にはパスワードが必要です:"
  [prompt.add_server]="追加するサーバー (user@host):"
  [prompt.remove_server]="削除するサーバー (番号またはホスト):"
  [empire.scan]="艦隊をスキャン中..."
  [empire.deploy]="命令を展開中:"
  [empire.completed]="スキャンが完了しました。"
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping 失敗:"
  [focus.title]="フォーカス"
  [focus.status_label]="ステータス"
  [focus.status_online]="オンライン"
  [focus.status_offline]="オフライン"
  [focus.menu.uptime]="Uptime を表示"
  [focus.menu.run]="コマンドを実行"
  [focus.menu.reboot]="再起動"
  [focus.menu.shutdown]="停止"
  [focus.menu.ssh]="インタラクティブ SSH を開く"
  [focus.menu.back]="艦隊に戻る"
  [focus.prompt.command]="実行するコマンド:"
  [focus.prompt.select]="番号またはホスト (例: 2 または root@web-01):"
  [focus.systems_available]="利用可能なシステム:"
  [plugins.title]="プラグインハンガー"
  [plugins.prompt.choice]="プラグインを選択 (0 で戻る):"
  [plugins.none]="読み込まれたプラグインはありません。"
  [msg.no_servers]="サーバーが見つかりません。"
  [alert.invalid]="無効な選択です。"
  [alert.cancel]="操作はキャンセルされました。"
  [victory.farewell]="帝国はあなたに敬礼する。"
)

declare -A L_ZH=(
  [tagline]="银河服务器控制"
  [quote]="“很好……让 SSH 在你体内流淌。”"
  [cfg_active]="当前配置:"
  [cfg_group]="分组"
  [cfg_user]="用户"
  [cfg_jobs]="已载入的系统"
  [cfg_timeout]="超时时间"
  [menu.scan]="扫描系统（ping + uptime）"
  [menu.run]="执行指令"
  [menu.reboot]="重启舰队"
  [menu.shutdown]="关闭舰队"
  [menu.focus]="控制单个系统（聚焦）"
  [menu.plugins]="打开插件机库"
  [menu.add_server]="添加服务器"
  [menu.remove_server]="移除服务器"
  [menu.back]="返回"
  [menu.quit]="退出帝国"
  [prompt.choice]="选择（或字母: s=scan, r=reboot, q=quit）："
  [prompt.choice_short]="选择:"
  [prompt.enter]="[按 Enter 继续]"
  [prompt.confirm]="确认吗？输入 Y 以确认:"
  [prompt.retry_interactive]="需要交互式重试？[y/N]:"
  [prompt.password_q]="需要密码:"
  [prompt.add_server]="要添加的服务器 (user@host)："
  [prompt.remove_server]="要移除的服务器（编号或主机）："
  [empire.scan]="正在扫描舰队..."
  [empire.deploy]="正在执行指令:"
  [empire.completed]="扫描完成。"
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping 失败:"
  [focus.title]="聚焦"
  [focus.status_label]="状态"
  [focus.status_online]="在线"
  [focus.status_offline]="离线"
  [focus.menu.uptime]="显示运行时间"
  [focus.menu.run]="执行命令"
  [focus.menu.reboot]="重启"
  [focus.menu.shutdown]="关闭"
  [focus.menu.ssh]="打开交互式 SSH"
  [focus.menu.back]="返回舰队"
  [focus.prompt.command]="要执行的命令:"
  [focus.prompt.select]="编号或主机（例如 2 或 root@web-01）："
  [focus.systems_available]="可用系统："
  [plugins.title]="插件机库"
  [plugins.prompt.choice]="选择插件（0 返回）："
  [plugins.none]="未加载任何插件。"
  [msg.no_servers]="未找到服务器。"
  [alert.invalid]="无效的选择。"
  [alert.cancel]="操作已取消。"
  [victory.farewell]="帝国向你致敬。"
)

declare -A L_KO=(
  [tagline]="은하 서버 제어"
  [quote]="\"좋아... SSH의 힘을 느껴라.\""
  [cfg_active]="활성 구성:"
  [cfg_group]="그룹"
  [cfg_user]="사용자"
  [cfg_jobs]="로드된 시스템"
  [cfg_timeout]="타임아웃"
  [menu.scan]="시스템 스캔 (ping + uptime)"
  [menu.run]="명령 실행"
  [menu.reboot]="함대를 재부팅"
  [menu.shutdown]="함대를 종료"
  [menu.focus]="시스템 제어 (포커스)"
  [menu.plugins]="플러그인 격납고 열기"
  [menu.add_server]="서버 추가"
  [menu.remove_server]="서버 제거"
  [menu.back]="뒤로"
  [menu.quit]="제국 떠나기"
  [prompt.choice]="선택 (또는 문자: s=scan, r=reboot, q=quit):"
  [prompt.choice_short]="선택:"
  [prompt.enter]="[계속하려면 Enter 키를 누르세요]"
  [prompt.confirm]="확인하시겠습니까? 확인하려면 Y 입력:"
  [prompt.retry_interactive]="인터랙티브 모드로 다시 시도할까요? [y/N]:"
  [prompt.password_q]="비밀번호가 필요한 대상:"
  [prompt.add_server]="추가할 서버 (user@host):"
  [prompt.remove_server]="제거할 서버 (번호 또는 호스트):"
  [empire.scan]="함대를 스캔하는 중..."
  [empire.deploy]="명령 실행 중:"
  [empire.completed]="스캔이 완료되었습니다."
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping 실패 대상:"
  [focus.title]="포커스"
  [focus.status_label]="상태"
  [focus.status_online]="온라인"
  [focus.status_offline]="오프라인"
  [focus.menu.uptime]="업타임 보기"
  [focus.menu.run]="명령 실행"
  [focus.menu.reboot]="재부팅"
  [focus.menu.shutdown]="종료"
  [focus.menu.ssh]="인터랙티브 SSH 열기"
  [focus.menu.back]="함대로 돌아가기"
  [focus.prompt.command]="실행할 명령:"
  [focus.prompt.select]="번호 또는 호스트 (예: 2 또는 root@web-01):"
  [focus.systems_available]="사용 가능한 시스템:"
  [plugins.title]="플러그인 격납고"
  [plugins.prompt.choice]="플러그인을 선택하세요 (0은 돌아가기):"
  [plugins.none]="로드된 플러그인이 없습니다."
  [msg.no_servers]="서버를 찾을 수 없습니다."
  [alert.invalid]="잘못된 선택입니다."
  [alert.cancel]="작업이 취소되었습니다."
  [victory.farewell]="제국이 당신에게 경의를 표합니다."
)

declare -A L_UK=(
  [tagline]="Галактичне керування серверами"
  [quote]="«Добре... нехай SSH тече крізь вас.»"
  [cfg_active]="Активна конфігурація:"
  [cfg_group]="Група"
  [cfg_user]="Користувач"
  [cfg_jobs]="Завантажені системи"
  [cfg_timeout]="Час очікування"
  [menu.scan]="Сканувати системи (ping + uptime)"
  [menu.run]="Виконати наказ"
  [menu.reboot]="Перезавантажити флот"
  [menu.shutdown]="Вимкнути флот"
  [menu.focus]="Керувати системою (фокус)"
  [menu.plugins]="Відкрити ангар плагінів"
  [menu.add_server]="Додати сервер"
  [menu.remove_server]="Видалити сервер"
  [menu.back]="Назад"
  [menu.quit]="Покинути Імперію"
  [prompt.choice]="Вибір (або літера: s=scan, r=reboot, q=quit):"
  [prompt.choice_short]="Вибір:"
  [prompt.enter]="[Натисніть Enter, щоб продовжити]"
  [prompt.confirm]="Підтвердити? Введіть Y для підтвердження:"
  [prompt.retry_interactive]="Повторити в інтерактивному режимі? [y/N]:"
  [prompt.password_q]="Потрібен пароль для"
  [prompt.add_server]="Сервер для додавання (user@host):"
  [prompt.remove_server]="Сервер для видалення (номер або host):"
  [empire.scan]="Сканування флоту..."
  [empire.deploy]="Виконання наказу:"
  [empire.completed]="Сканування завершено."
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping не вдався для"
  [focus.title]="Фокус"
  [focus.status_label]="Статус"
  [focus.status_online]="в мережі"
  [focus.status_offline]="поза мережею"
  [focus.menu.uptime]="Показати uptime"
  [focus.menu.run]="Виконати команду"
  [focus.menu.reboot]="Перезавантажити"
  [focus.menu.shutdown]="Вимкнути"
  [focus.menu.ssh]="Відкрити інтерактивний SSH"
  [focus.menu.back]="Повернутися до флоту"
  [focus.prompt.command]="Команда для виконання:"
  [focus.prompt.select]="Номер або хост (наприклад 2 чи root@web-01):"
  [focus.systems_available]="Доступні системи:"
  [plugins.title]="Ангар плагінів"
  [plugins.prompt.choice]="Оберіть плагін (0 для повернення):"
  [plugins.none]="Плагіни не завантажено."
  [msg.no_servers]="Сервери не знайдені."
  [alert.invalid]="Неприпустимий вибір."
  [alert.cancel]="Операцію скасовано."
  [victory.farewell]="Імперія вітає вас."
)

declare -A L_PL=(
  [tagline]="Galaktyczne zarządzanie serwerami"
  [quote]="\"Dobrze... niech SSH przepływa przez ciebie.\""
  [cfg_active]="Aktywna konfiguracja:"
  [cfg_group]="Grupa"
  [cfg_user]="Użytkownik"
  [cfg_jobs]="Załadowane systemy"
  [cfg_timeout]="Limit czasu"
  [menu.scan]="Skanuj systemy (ping + uptime)"
  [menu.run]="Wykonaj rozkaz"
  [menu.reboot]="Restartuj flotę"
  [menu.shutdown]="Wyłącz flotę"
  [menu.focus]="Steruj systemem (focus)"
  [menu.plugins]="Otwórz hangar wtyczek"
  [menu.add_server]="Dodaj serwer"
  [menu.remove_server]="Usuń serwer"
  [menu.back]="Wróć"
  [menu.quit]="Opuść Imperium"
  [prompt.choice]="Wybór (lub litera: s=scan, r=reboot, q=quit):"
  [prompt.choice_short]="Wybór:"
  [prompt.enter]="[Naciśnij Enter, aby kontynuować]"
  [prompt.confirm]="Potwierdzić? Wpisz Y, aby potwierdzić:"
  [prompt.retry_interactive]="Ponowić w trybie interaktywnym? [y/N]:"
  [prompt.password_q]="Wymagane hasło dla"
  [prompt.add_server]="Serwer do dodania (user@host):"
  [prompt.remove_server]="Serwer do usunięcia (numer lub host):"
  [empire.scan]="Skanowanie floty..."
  [empire.deploy]="Wykonywanie rozkazu:"
  [empire.completed]="Skanowanie zakończone."
  [status.ping_ok]="Ping: OK"
  [status.ping_fail]="Ping nie powiódł się dla"
  [focus.title]="Focus"
  [focus.status_label]="Status"
  [focus.status_online]="online"
  [focus.status_offline]="offline"
  [focus.menu.uptime]="Pokaż uptime"
  [focus.menu.run]="Wykonaj polecenie"
  [focus.menu.reboot]="Restartuj"
  [focus.menu.shutdown]="Wyłącz"
  [focus.menu.ssh]="Otwórz interaktywny SSH"
  [focus.menu.back]="Wróć do floty"
  [focus.prompt.command]="Polecenie do wykonania:"
  [focus.prompt.select]="Numer lub host (np. 2 lub root@web-01):"
  [focus.systems_available]="Dostępne systemy:"
  [plugins.title]="Hangar wtyczek"
  [plugins.prompt.choice]="Wybierz wtyczkę (0 aby wrócić):"
  [plugins.none]="Brak załadowanych wtyczek."
  [msg.no_servers]="Nie znaleziono serwerów."
  [alert.invalid]="Nieprawidłowy wybór."
  [alert.cancel]="Operacja anulowana."
  [victory.farewell]="Imperium salutuje."
)

__tr_en(){
  local key="$1"
  case "$key" in
    app_name) echo "$APP_NAME" ;;
    tagline) echo "$TAGLINE" ;;
    quote) echo "\"Good... let the SSH flow through you.\"" ;;
    cfg_active) echo "Active configuration:" ;;
    cfg_group) echo "Group" ;;
    cfg_user) echo "User" ;;
    cfg_jobs) echo "Loaded systems" ;;
    cfg_timeout) echo "Timeout" ;;
    menu.scan) echo "Scan systems (ping + uptime)" ;;
    menu.run) echo "Execute an order" ;;
    menu.reboot) echo "Reboot the fleet" ;;
    menu.shutdown) echo "Shutdown the fleet" ;;
    menu.focus) echo "Control a system (focus)" ;;
    menu.plugins) echo "Open the plugin bay" ;;
    menu.add_server) echo "Add a server" ;;
    menu.remove_server) echo "Remove a server" ;;
    menu.back) echo "Return" ;;
    menu.quit) echo "Quit the Empire" ;;
    prompt.choice) echo "Choice (or letter: s=scan, r=reboot, q=quit):" ;;
    prompt.choice_short) echo "Choice:" ;;
    prompt.enter) echo "[Press Enter to continue]" ;;
    prompt.confirm) echo "Confirm? Type Y to confirm:" ;;
    prompt.retry_interactive) echo "Retry interactively? [y/N]:" ;;
    prompt.password_q) echo "Password required for" ;;
    prompt.add_server) echo "Server to add (user@host):" ;;
    prompt.remove_server) echo "Server to remove (number or host):" ;;
    empire.scan) echo "Scanning the fleet..." ;;
    empire.deploy) echo "Deploying the order:" ;;
    empire.completed) echo "Scan finished." ;;
    status.ping_ok) echo "Ping: OK" ;;
    status.ping_fail) echo "Ping failed for" ;;
    focus.title) echo "Focus" ;;
    focus.status_label) echo "Status" ;;
    focus.status_online) echo "online" ;;
    focus.status_offline) echo "offline" ;;
    focus.menu.uptime) echo "Check uptime" ;;
    focus.menu.run) echo "Execute command" ;;
    focus.menu.reboot) echo "Reboot" ;;
    focus.menu.shutdown) echo "Shutdown" ;;
    focus.menu.ssh) echo "Open interactive SSH" ;;
    focus.menu.back) echo "Return to fleet" ;;
    focus.prompt.command) echo "Command to run:" ;;
    focus.prompt.select) echo "Num or hostname (e.g. 2 or root@web-01):" ;;
    focus.systems_available) echo "Systems available:" ;;
    plugins.title) echo "Plugin hangar" ;;
    plugins.prompt.choice) echo "Select a plugin (0 to return):" ;;
    plugins.none) echo "No plugins loaded." ;;
    plugin.backup.label) echo "Imperial backups" ;;
    plugin.backup.title) echo "[BAK] Imperial backup module" ;;
    plugin.backup.option_etc) echo "Backup /etc on all servers" ;;
    plugin.backup.option_www) echo "Backup /var/www on all servers" ;;
    plugin.backup.log_etc) echo "Backing up /etc" ;;
    plugin.backup.log_www) echo "Backing up /var/www" ;;
    plugin.monitoring.label) echo "Imperial monitoring" ;;
    plugin.monitoring.title) echo "[MON] Imperial monitoring" ;;
    msg.no_servers) echo "No servers found." ;;
    alert.invalid) echo "Invalid choice." ;;
    alert.cancel) echo "Operation cancelled." ;;
    victory.farewell) echo "The Empire salutes you." ;;
    *) echo "$key" ;;
  esac
}

__translation_from_map(){
  local map_name="$1" key="$2"
  if ! declare -p "$map_name" >/dev/null 2>&1; then
    return 1
  fi
  local -n map_ref="$map_name"
  if [[ ${map_ref[$key]+_} ]]; then
    printf '%s\n' "${map_ref[$key]}"
    return 0
  fi
  return 1
}

__tr_with_map(){
  local map_name="$1" key="$2"
  if __translation_from_map "$map_name" "$key"; then
    return 0
  fi
  __tr_en "$key"
}

# ----------------------------
# Layout helpers
# ----------------------------
_TERM_MIN_WIDTH=48

get_term_width(){
  local cols
  if cols=$(tput cols 2>/dev/null); then
    if (( cols < _TERM_MIN_WIDTH )); then
      echo "$_TERM_MIN_WIDTH"
    else
      echo "$cols"
    fi
  else
    echo 72
  fi
}

strip_ansi(){
  printf '%s' "$*" | sed -E $'s/\x1B\[[0-9;]*[A-Za-z]//g'
}

repeat_char(){
  local char="$1" count="$2" line
  if (( count <= 0 )); then
    printf ''
    return
  fi
  printf -v line '%*s' "$count" ''
  printf '%s' "${line// /$char}"
}

pad_line(){
  local text="$1" width="${2:-$(get_term_width)}"
  local plain
  plain="$(strip_ansi "$text")"
  local len=${#plain}
  if (( len >= width )); then
    echo "$text"
  else
    printf '%s%s' "$text" "$(repeat_char ' ' $((width - len)))"
  fi
}

# L(key) returns translated string according to UI_LANG
L(){
  local key="$1"
  local lang="${UI_LANG,,}"
  case "$lang" in
    fr)
      case "$key" in
        app_name) echo "$APP_NAME" ;;
        tagline) echo "$TAGLINE" ;;
        quote) echo "« Que le SSH coule en vous. »" ;;
        cfg_active) echo "Active configuration:" ;;
        cfg_group) echo "Group" ;;
        cfg_user) echo "User" ;;
        cfg_jobs) echo "Loaded systems" ;;
        cfg_timeout) echo "Timeout" ;;
        menu.scan) echo "Scan systems (ping + uptime)" ;;
        menu.run) echo "Execute an order" ;;
        menu.reboot) echo "Reboot the fleet" ;;
        menu.shutdown) echo "Shutdown the fleet" ;;
        menu.focus) echo "Control a system (focus)" ;;
        menu.plugins) echo "Ouvrir le hangar à plugins" ;;
        menu.add_server) echo "Ajouter un serveur" ;;
        menu.remove_server) echo "Supprimer un serveur" ;;
        menu.back) echo "Retour" ;;
        menu.quit) echo "Quit the Empire" ;;
        prompt.choice) echo "Choice (or letter: s=scan, r=reboot, q=quit):" ;;
        prompt.choice_short) echo "Choix :" ;;
        prompt.enter) echo "[Press Enter to continue]" ;;
        prompt.confirm) echo "Confirm? Type O to confirm:" ;;
        prompt.retry_interactive) echo "Réessayer en interactif ? [o/N]:" ;;
        prompt.add_server) echo "Serveur à ajouter (user@hôte) :" ;;
        prompt.remove_server) echo "Serveur à supprimer (numéro ou hôte) :" ;;
        prompt.password_q) echo "Password required for" ;;
        empire.scan) echo "Scanning the fleet..." ;;
        empire.deploy) echo "Deploying the order:" ;;
        empire.completed) echo "Scan finished." ;;
        status.ping_ok) echo "Ping: OK" ;;
        status.ping_fail) echo "Ping failed for" ;;
        focus.title) echo "Focus" ;;
        focus.status_label) echo "Statut" ;;
        focus.status_online) echo "en ligne" ;;
        focus.status_offline) echo "hors ligne" ;;
        focus.menu.uptime) echo "Consulter l'uptime" ;;
        focus.menu.run) echo "Exécuter une commande" ;;
        focus.menu.reboot) echo "Redémarrer" ;;
        focus.menu.shutdown) echo "Éteindre" ;;
        focus.menu.ssh) echo "Ouvrir un SSH interactif" ;;
        focus.menu.back) echo "Retour à la flotte" ;;
        focus.prompt.command) echo "Commande à exécuter :" ;;
        focus.prompt.select) echo "Numéro ou hôte (ex. 2 ou root@web-01) :" ;;
        focus.systems_available) echo "Systèmes disponibles :" ;;
        plugins.title) echo "Hangar à plugins" ;;
        plugins.prompt.choice) echo "Choisissez un plugin (0 pour revenir) :" ;;
        plugins.none) echo "Aucun plugin chargé." ;;
        plugin.backup.label) echo "Sauvegardes impériales" ;;
        plugin.backup.title) echo "📦 Module de sauvegarde impériale" ;;
        plugin.backup.option_etc) echo "Sauvegarder /etc sur tous les serveurs" ;;
        plugin.backup.option_www) echo "Sauvegarder /var/www sur tous les serveurs" ;;
        plugin.backup.log_etc) echo "Sauvegarde de /etc" ;;
        plugin.backup.log_www) echo "Sauvegarde de /var/www" ;;
        plugin.monitoring.label) echo "Monitoring impérial" ;;
        plugin.monitoring.title) echo "🛰️ Monitoring impérial" ;;
        msg.no_servers) echo "No servers found." ;;
        alert.invalid) echo "Invalid choice." ;;
        alert.cancel) echo "Operation cancelled." ;;
        victory.farewell) echo "The Empire salutes you." ;;
        *) echo "$key" ;; # fallback prints key
      esac
      ;;
    ""|en)
      __tr_en "$key"
      ;;
    ru|ru-ru)
      __tr_with_map L_RU "$key"
      ;;
    de|de-de)
      __tr_with_map L_DE "$key"
      ;;
    es|es-es|es-mx|es-latam)
      __tr_with_map L_ES "$key"
      ;;
    pt|pt-br|pt-pt)
      __tr_with_map L_PT "$key"
      ;;
    it|it-it)
      __tr_with_map L_IT "$key"
      ;;
    ja|ja-jp)
      __tr_with_map L_JA "$key"
      ;;
    zh|zh-cn|zh-hans|zh-hant|zh-tw)
      __tr_with_map L_ZH "$key"
      ;;
    ko|ko-kr)
      __tr_with_map L_KO "$key"
      ;;
    uk|uk-ua)
      __tr_with_map L_UK "$key"
      ;;
    pl|pl-pl)
      __tr_with_map L_PL "$key"
      ;;
    *)
      __tr_en "$key"
      ;;
  esac
}

# UI drawing helpers
draw_line(){
  local width
  width=$(get_term_width)
  printf "%b%s%b\n" "$COL_MUTED" "$(repeat_char '-' "$width")" "$COL_RESET"
}

draw_block_top(){
  local width
  width=$(get_term_width)
  printf "%b+%s+%b\n" "$COL_FRAME" "$(repeat_char '-' $((width-2)))" "$COL_RESET"
}

draw_block_bot(){
  local width
  width=$(get_term_width)
  printf "%b+%s+%b\n" "$COL_FRAME" "$(repeat_char '-' $((width-2)))" "$COL_RESET"
}

draw_center(){
  local text="$1" width inner padding remaining plain
  width=$(get_term_width)
  inner=$((width-2))
  plain="$(strip_ansi "$text")"
  if (( ${#plain} > inner )); then
    text="${plain:0:inner}"
    plain="$text"
  fi
  padding=$(( (inner - ${#plain}) / 2 ))
  remaining=$(( inner - ${#plain} - padding ))
  printf "%b|%s%s%s|%b\n" \
    "$COL_FRAME" "$(repeat_char ' ' "$padding")" "$text" "$(repeat_char ' ' "$remaining")" "$COL_RESET"
}

draw_section_title(){
  local width
  width=$(get_term_width)
  printf "%b%s%b\n" "$COL_INFO" "$(pad_line " >> $1" "$width")" "$COL_RESET"
}

draw_menu_option(){
  local key="$1" icon="$2" label="$3" hint="${4:-}"
  printf " %b[%s]%b  %b%s %s%b" "$COL_INFO" "$key" "$COL_RESET" "$COL_MENU" "$icon" "$label" "$COL_RESET"
  if [[ -n "$hint" ]]; then
    printf " %b%s%b" "$COL_SUB" "$hint" "$COL_RESET"
  fi
  printf "\n"
}

draw_stat_row(){
  local label1="$1" value1="$2" label2="${3:-}" value2="${4:-}"
  local line=" ${label1} : ${value1}"
  if [[ -n "$label2" ]]; then
    line+="    ${label2} : ${value2}"
  fi
  echo -e "$line"
}

# k9s-style status bar (top)
draw_status_bar(){
  local width
  width=$(get_term_width)

  local loaded=0
  if declare -p SERVERS >/dev/null 2>&1; then
    loaded=${#SERVERS[@]}
  fi

  local ctx=" Context: ${COL_MENU}${GROUP}${COL_RESET}"
  local user=" User: ${COL_MENU}${SSH_USER}${COL_RESET}"
  local targets=" Targets: ${COL_MENU}${loaded}${COL_RESET}"
  local timeout=" Timeout: ${COL_MENU}${SSH_TIMEOUT}s${COL_RESET}"

  printf "%b" "$COL_INFO"
  printf "%-${width}s" "${ctx}${user}${targets}${timeout}"
  printf "%b\n" "$COL_RESET"
}

# k9s-style header
draw_header(){
  clear
  local width
  width=$(get_term_width)

  # Top banner with TIE Fighter
  printf "%b" "$COL_HEADER"
  printf "%${width}s\n" | tr ' ' '='
  echo "     .-|~|-.        PALPATINE ${VERSION} - Imperial Fleet Control System"
  echo "  .-[=======]-.     \"Long Live The Empire\""
  echo "     '-|~|-'  "
  printf "%${width}s\n" | tr ' ' '='
  printf "%b\n" "$COL_RESET"

  # Status bar
  draw_status_bar
  draw_line
}

# k9s-style command menu (bottom)
draw_command_menu(){
  local width
  width=$(get_term_width)
  draw_line
  printf "%b" "$COL_SUB"
  echo " <1> Scan Fleet | <2> Run Command | <3> Reboot | <4> Shutdown | <5> Focus | <6> Plugins | <q> Quit"
  printf "%b" "$COL_RESET"
  draw_line
}

# k9s-style server table
draw_server_table(){
  local title="${1:-IMPERIAL FLEET ROSTER}"

  echo ""
  printf "%b" "$COL_INFO"
  echo " $title"
  printf "%b" "$COL_RESET"
  draw_line

  # Table header
  printf "%b" "$COL_MENU"
  printf " %-4s | %-40s | %-10s | %-15s\n" "ID" "TARGET" "STATUS" "TAGS"
  printf "%b" "$COL_RESET"
  draw_line

  # Table rows
  local i=1
  for s in "${SERVERS[@]}"; do
    local tags="${SERVER_TAGS[$s]:-none}"
    [[ -z "$tags" ]] && tags="none"

    # Ping status indicator
    local status_col="$COL_MUTED"
    local status_txt="UNKNOWN"

    printf " %b%-4s%b | %-40s | %b%-10s%b | %-15s\n" \
      "$COL_SUB" "$i" "$COL_RESET" \
      "$s" \
      "$status_col" "$status_txt" "$COL_RESET" \
      "$tags"
    ((i++))
  done

  draw_line
  echo ""
}

# Branded logging wrappers (Star Wars Imperial style)
empire(){ echo -e "${COL_INFO}[IMPERIAL]${COL_RESET} $*"; }
victory(){ echo -e "${COL_OK}[OK]${COL_RESET} $*"; }
alert(){ echo -e "${COL_WARN}[WARNING]${COL_RESET} $*"; }
failure(){ echo -e "${COL_ERR}[FAILED]${COL_RESET} $*"; }
