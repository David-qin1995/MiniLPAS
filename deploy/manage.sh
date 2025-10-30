#!/bin/bash
# MiniLPA 服务管理脚本
# 用于管理 minilpa-backend 和 minilpa-agent 服务（优先通过 Docker Compose，其次 systemd）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务名称
BACKEND_SERVICE="minilpa-backend"
AGENT_SERVICE="minilpa-agent"
INSTALL_DIR="/www/wwwroot/minilpa"
WEB_COMPOSE="$INSTALL_DIR/web/docker-compose.yml"
AGENT_COMPOSE="$INSTALL_DIR/agent/docker-compose.yml"
DOCKER_BIN=$(command -v docker || true)
DC_CMD="docker compose"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}MiniLPA 服务管理脚本${NC}"
    echo ""
    echo "用法: $0 [命令] [服务]"
    echo ""
    echo "命令:"
    echo "适用于两个服务:"
    echo "  status       - 查看服务状态（默认）"
    echo "  logs         - 查看服务日志"
    echo "  restart      - 重启服务"
    echo "  start        - 启动服务"
    echo "  stop         - 停止服务"
    echo "  enable       - 设置服务开机自启（systemd 模式）"
    echo "  disable      - 取消服务开机自启（systemd 模式）"
    echo ""
    echo "仅查看:"
    echo "  health       - 检查服务健康状态（包括API测试）"
    echo "  info         - 显示服务详细信息（systemd 模式）"
    echo "  ports        - 检查端口占用情况"
    echo ""
    echo "服务名称:"
    echo "  backend      - 后端服务 ($BACKEND_SERVICE)"
    echo "  agent        - 代理服务 ($AGENT_SERVICE)"
    echo "  all          - 所有服务（默认）"
}

# 检查是否为root用户（某些操作需要）
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${YELLOW}警告: 某些操作需要 root 权限，请使用 sudo${NC}"
        return 1
    fi
    return 0
}

# 获取服务名称
get_service_name() {
    case "$1" in
        backend)
            echo "$BACKEND_SERVICE"
            ;;
        agent)
            echo "$AGENT_SERVICE"
            ;;
        *)
            echo ""
            ;;
    esac
}

# 显示服务状态
show_status() {
    local service_name="$1"

    # Docker 模式优先
    if [ -n "$DOCKER_BIN" ] && { [ -f "$WEB_COMPOSE" ] || [ -f "$AGENT_COMPOSE" ]; }; then
        echo -e "${BLUE}=== Docker 服务状态 ===${NC}\n"
        if [ -f "$WEB_COMPOSE" ]; then
            echo -e "${BLUE}[web] $WEB_COMPOSE${NC}"
            $DC_CMD -f "$WEB_COMPOSE" ps || true
            echo ""
        fi
        if [ -f "$AGENT_COMPOSE" ]; then
            echo -e "${BLUE}[agent] $AGENT_COMPOSE${NC}"
            $DC_CMD -f "$AGENT_COMPOSE" ps || true
            echo ""
        fi
        return
    fi

    if [ -z "$service_name" ]; then
        # 显示所有服务状态（systemd）
        echo -e "${BLUE}=== 服务状态总览 ===${NC}\n"
        show_status "$BACKEND_SERVICE"
        echo ""
        show_status "$AGENT_SERVICE"
        return
    fi

    echo -e "${BLUE}服务: $service_name${NC}"

    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
        echo -e "状态: ${GREEN}运行中 ✓${NC}"
    elif systemctl is-failed --quiet "$service_name" 2>/dev/null; then
        echo -e "状态: ${RED}失败 ✗${NC}"
    else
        echo -e "状态: ${YELLOW}已停止${NC}"
    fi

    # 显示是否开机自启
    if systemctl is-enabled --quiet "$service_name" 2>/dev/null; then
        echo "开机自启: 是"
    else
        echo "开机自启: 否"
    fi

    # 显示进程信息
    local pid=$(systemctl show -p MainPID --value "$service_name" 2>/dev/null)
    if [ -n "$pid" ] && [ "$pid" != "0" ]; then
        echo "进程ID: $pid"
        # 显示CPU和内存使用
        if ps -p "$pid" > /dev/null 2>&1; then
            ps -p "$pid" -o pid,pcpu,pmem,etime,cmd --no-headers 2>/dev/null | awk '{printf "CPU: %s%%, 内存: %s%%, 运行时间: %s\n", $2, $3, $4}'
        fi
    fi

    # 显示最近的日志摘要
    echo -e "\n${BLUE}最近日志:${NC}"
    journalctl -u "$service_name" -n 3 --no-pager --no-full 2>/dev/null | tail -3 | sed 's/^/  /' || echo "  无法获取日志"
}

# 显示服务日志
show_logs() {
    local service_name="$1"
    local lines="${2:-50}"

    # Docker 模式
    if [ -n "$DOCKER_BIN" ] && { [ -f "$WEB_COMPOSE" ] || [ -f "$AGENT_COMPOSE" ]; }; then
        if [ -z "$service_name" ]; then
            echo -e "${YELLOW}请指定服务名称 (backend 或 agent)${NC}"
            return 1
        fi
        case "$service_name" in
            backend)
                [ -f "$WEB_COMPOSE" ] && $DC_CMD -f "$WEB_COMPOSE" logs --tail "$lines" backend || true
                ;;
            agent)
                [ -f "$AGENT_COMPOSE" ] && $DC_CMD -f "$AGENT_COMPOSE" logs --tail "$lines" minilpa-agent || true
                ;;
        esac
        return
    fi

    if [ -z "$service_name" ]; then
        echo -e "${YELLOW}请指定服务名称 (backend 或 agent)${NC}"
        echo "用法: $0 logs [backend|agent] [行数，默认50]"
        return 1
    fi

    echo -e "${BLUE}=== $service_name 服务日志（最近 $lines 行）===${NC}\n"
    journalctl -u "$service_name" -n "$lines" --no-pager
}

# 查看实时日志
show_logs_follow() {
    local service_name="$1"

    # Docker 模式
    if [ -n "$DOCKER_BIN" ] && { [ -f "$WEB_COMPOSE" ] || [ -f "$AGENT_COMPOSE" ]; }; then
        case "$service_name" in
            backend)
                [ -f "$WEB_COMPOSE" ] && $DC_CMD -f "$WEB_COMPOSE" logs -f backend || true
                ;;
            agent)
                [ -f "$AGENT_COMPOSE" ] && $DC_CMD -f "$AGENT_COMPOSE" logs -f minilpa-agent || true
                ;;
        esac
        return
    fi

    if [ -z "$service_name" ]; then
        echo -e "${YELLOW}请指定服务名称 (backend 或 agent)${NC}"
        return 1
    fi

    echo -e "${BLUE}=== $service_name 实时日志 (按 Ctrl+C 退出) ===${NC}\n"
    journalctl -u "$service_name" -f
}

# 重启服务
restart_service() {
    local service_name="$1"

    # Docker 模式
    if [ -n "$DOCKER_BIN" ] && { [ -f "$WEB_COMPOSE" ] || [ -f "$AGENT_COMPOSE" ]; }; then
        if [ -z "$service_name" ]; then
            echo -e "${BLUE}重启所有 Docker 服务...${NC}"
            [ -f "$WEB_COMPOSE" ] && $DC_CMD -f "$WEB_COMPOSE" up -d --remove-orphans
            [ -f "$AGENT_COMPOSE" ] && $DC_CMD -f "$AGENT_COMPOSE" up -d --remove-orphans
            return
        fi
        case "$service_name" in
            "$BACKEND_SERVICE")
                [ -f "$WEB_COMPOSE" ] && $DC_CMD -f "$WEB_COMPOSE" up -d backend || true
                ;;
            "$AGENT_SERVICE")
                [ -f "$AGENT_COMPOSE" ] && $DC_CMD -f "$AGENT_COMPOSE" up -d minilpa-agent || true
                ;;
        esac
        return
    fi

    check_root || return 1

    if [ -z "$service_name" ]; then
        echo -e "${BLUE}重启所有服务...${NC}"
        restart_service "$BACKEND_SERVICE"
        sleep 2
        restart_service "$AGENT_SERVICE"
        return
    fi

    echo -e "${BLUE}正在重启服务: $service_name${NC}"
    systemctl restart "$service_name" || {
        echo -e "${RED}重启失败！${NC}"
        return 1
    }

    sleep 2

    if systemctl is-active --quiet "$service_name"; then
        echo -e "${GREEN}✓ 服务已成功重启${NC}"
    else
        echo -e "${RED}✗ 服务重启后未运行${NC}"
        echo "查看日志: journalctl -u $service_name -n 30"
        return 1
    fi
}

# 启动服务
start_service() {
    local service_name="$1"

    # Docker 模式
    if [ -n "$DOCKER_BIN" ] && { [ -f "$WEB_COMPOSE" ] || [ -f "$AGENT_COMPOSE" ]; }; then
        if [ -z "$service_name" ]; then
            echo -e "${BLUE}启动所有 Docker 服务...${NC}"
            [ -f "$WEB_COMPOSE" ] && $DC_CMD -f "$WEB_COMPOSE" up -d
            [ -f "$AGENT_COMPOSE" ] && $DC_CMD -f "$AGENT_COMPOSE" up -d
            return
        fi
        case "$service_name" in
            "$BACKEND_SERVICE")
                [ -f "$WEB_COMPOSE" ] && $DC_CMD -f "$WEB_COMPOSE" up -d backend || true
                ;;
            "$AGENT_SERVICE")
                [ -f "$AGENT_COMPOSE" ] && $DC_CMD -f "$AGENT_COMPOSE" up -d minilpa-agent || true
                ;;
        esac
        return
    fi

    check_root || return 1

    if [ -z "$service_name" ]; then
        echo -e "${BLUE}启动所有服务...${NC}"
        start_service "$BACKEND_SERVICE"
        sleep 2
        start_service "$AGENT_SERVICE"
        return
    fi

    echo -e "${BLUE}正在启动服务: $service_name${NC}"

    if systemctl is-active --quiet "$service_name"; then
        echo -e "${YELLOW}服务已在运行中${NC}"
        return 0
    fi

    systemctl start "$service_name" || {
        echo -e "${RED}启动失败！${NC}"
        return 1
    }

    sleep 2

    if systemctl is-active --quiet "$service_name"; then
        echo -e "${GREEN}✓ 服务已成功启动${NC}"
    else
        echo -e "${RED}✗ 服务启动失败${NC}"
        echo "查看日志: journalctl -u $service_name -n 30"
        return 1
    fi
}

# 停止服务
stop_service() {
    local service_name="$1"

    # Docker 模式
    if [ -n "$DOCKER_BIN" ] && { [ -f "$WEB_COMPOSE" ] || [ -f "$AGENT_COMPOSE" ]; }; then
        if [ -z "$service_name" ]; then
            echo -e "${BLUE}停止所有 Docker 服务...${NC}"
            [ -f "$WEB_COMPOSE" ] && $DC_CMD -f "$WEB_COMPOSE" down || true
            [ -f "$AGENT_COMPOSE" ] && $DC_CMD -f "$AGENT_COMPOSE" down || true
            return
        fi
        case "$service_name" in
            "$BACKEND_SERVICE")
                [ -f "$WEB_COMPOSE" ] && $DC_CMD -f "$WEB_COMPOSE" stop backend || true
                ;;
            "$AGENT_SERVICE")
                [ -f "$AGENT_COMPOSE" ] && $DC_CMD -f "$AGENT_COMPOSE" stop minilpa-agent || true
                ;;
        esac
        return
    fi

    check_root || return 1

    if [ -z "$service_name" ]; then
        echo -e "${BLUE}停止所有服务...${NC}"
        stop_service "$BACKEND_SERVICE"
        stop_service "$AGENT_SERVICE"
        return
    fi

    echo -e "${BLUE}正在停止服务: $service_name${NC}"

    if ! systemctl is-active --quiet "$service_name"; then
        echo -e "${YELLOW}服务已停止${NC}"
        return 0
    fi

    systemctl stop "$service_name" || {
        echo -e "${RED}停止失败！${NC}"
        return 1
    }

    sleep 1

    if ! systemctl is-active --quiet "$service_name"; then
        echo -e "${GREEN}✓ 服务已成功停止${NC}"
    else
        echo -e "${RED}✗ 服务停止失败，尝试强制停止...${NC}"
        systemctl kill -s SIGKILL "$service_name" 2>/dev/null || true
    fi
}

# 设置开机自启（systemd）
enable_service() {
    local service_name="$1"

    check_root || return 1

    if [ -z "$service_name" ]; then
        echo -e "${BLUE}设置所有服务开机自启...${NC}"
        enable_service "$BACKEND_SERVICE"
        enable_service "$AGENT_SERVICE"
        return
    fi

    echo -e "${BLUE}设置服务开机自启: $service_name${NC}"
    systemctl enable "$service_name" && echo -e "${GREEN}✓ 已设置开机自启${NC}"
}

# 取消开机自启（systemd）
disable_service() {
    local service_name="$1"

    check_root || return 1

    if [ -z "$service_name" ]; then
        echo -e "${BLUE}取消所有服务开机自启...${NC}"
        disable_service "$BACKEND_SERVICE"
        disable_service "$AGENT_SERVICE"
        return
    fi

    echo -e "${BLUE}取消服务开机自启: $service_name${NC}"
    systemctl disable "$service_name" && echo -e "${GREEN}✓ 已取消开机自启${NC}"
}

# 检查服务健康状态
check_health() {
    echo -e "${BLUE}=== 服务健康检查 ===${NC}\n"

    # 检查后端服务
    echo -e "${BLUE}1. 后端服务状态:${NC}"
    if curl -s -f -m 5 http://127.0.0.1:8080/api/devices/status > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ API可访问${NC}"
        local response=$(curl -s http://127.0.0.1:8080/api/devices/status 2>/dev/null)
        echo "  响应: $response" | head -200
    else
        echo -e "  ${RED}✗ API无法访问${NC}"
    fi

    echo ""

    # 检查代理服务（容器是否运行）
    if [ -n "$DOCKER_BIN" ] && [ -f "$AGENT_COMPOSE" ]; then
        echo -e "${BLUE}2. 代理服务容器:${NC}"
        $DC_CMD -f "$AGENT_COMPOSE" ps || true
    fi

    echo ""

    # 端口检查
    echo -e "${BLUE}3. 端口占用情况:${NC}"
    if command -v ss > /dev/null 2>&1; then
        ss -tlnp 2>/dev/null | grep -E ":8080|:8081" | sed 's/^/  /' || echo "  未发现相关端口监听"
    elif command -v netstat > /dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep -E ":8080|:8081" | sed 's/^/  /' || echo "  未发现相关端口监听"
    else
        echo "  无法检查端口（需要 ss 或 netstat）"
    fi
}

# 显示服务详细信息（systemd）
show_info() {
    local service_name="$1"

    if [ -z "$service_name" ]; then
        show_info "$BACKEND_SERVICE"
        echo ""
        show_info "$AGENT_SERVICE"
        return
    fi

    echo -e "${BLUE}=== $service_name 详细信息 ===${NC}\n"
    systemctl status "$service_name" --no-pager -l | head -20
    echo ""
    echo -e "${BLUE}服务文件路径:${NC}"
    systemctl cat "$service_name" 2>/dev/null | head -30 || echo "无法读取服务文件"
}

# 检查端口占用
check_ports() {
    echo -e "${BLUE}=== 端口占用情况 ===${NC}\n"

    if command -v ss > /dev/null 2>&1; then
        echo "8080/8081 监听:"
        ss -tlnp 2>/dev/null | grep -E ":8080|:8081" | sed 's/^/  /' || echo "  未发现"
    elif command -v netstat > /dev/null 2>&1; then
        echo "8080/8081 监听:"
        netstat -tlnp 2>/dev/null | grep -E ":8080|:8081" | sed 's/^/  /' || echo "  未发现"
    else
        echo "错误: 系统未安装 ss 或 netstat"
    fi
}

# 主函数
interactive_menu() {
    while true; do
        echo -e "${BLUE}==== MiniLPA 管理菜单 ====${NC}"
        echo "1) 查看状态"
        echo "2) 启动服务"
        echo "3) 停止服务"
        echo "4) 重启服务"
        echo "5) 查看日志"
        echo "6) 跟随实时日志"
        echo "7) 健康检查"
        echo "8) 查看端口"
        echo "9) 退出"
        echo ""
        read -rp "请选择操作 [1-9]: " op

        case "$op" in
            1) action="status" ;;
            2) action="start" ;;
            3) action="stop" ;;
            4) action="restart" ;;
            5) action="logs" ;;
            6) action="logs-follow" ;;
            7) action="health" ;;
            8) action="ports" ;;
            9) echo "已退出"; exit 0 ;;
            *) echo -e "${YELLOW}无效选择${NC}"; continue ;;
        esac

        if [ "$action" = "health" ] || [ "$action" = "ports" ]; then
            : # 不需要选择具体服务
        else
            echo ""
            echo "服务: 1) backend  2) agent  3) all"
            read -rp "请选择服务 [1-3]: " svc_sel
            case "$svc_sel" in
                1) target="backend" ;;
                2) target="agent" ;;
                3) target="all" ;;
                *) echo -e "${YELLOW}无效服务${NC}"; continue ;;
            esac
        fi

        echo ""
        case "$action" in
            status)
                if [ "$target" = "all" ]; then show_status; else show_status "$(get_service_name "$target")"; fi ;;
            start)
                if [ "$target" = "all" ]; then start_service; else start_service "$(get_service_name "$target")"; fi ;;
            stop)
                if [ "$target" = "all" ]; then stop_service; else stop_service "$(get_service_name "$target")"; fi ;;
            restart)
                if [ "$target" = "all" ]; then restart_service; else restart_service "$(get_service_name "$target")"; fi ;;
            logs)
                if [ -z "$target" ]; then echo -e "${YELLOW}未选择服务${NC}"; else show_logs "$target" 100; fi ;;
            logs-follow)
                if [ -z "$target" ]; then echo -e "${YELLOW}未选择服务${NC}"; else show_logs_follow "$target"; fi ;;
            health)
                check_health ;;
            ports)
                check_ports ;;
        esac

        echo ""
        read -rp "按回车返回菜单..." _
        clear
    done
}

main() {
    if [ -t 0 ] && [ -z "$1" ]; then
        clear
        interactive_menu
        exit 0
    fi

    local command="${1:-status}"
    local service="${2:-all}"

    case "$command" in
        status|st)
            if [ "$service" = "all" ]; then
                show_status
            else
                local svc=$(get_service_name "$service")
                if [ -z "$svc" ]; then
                    echo -e "${RED}错误: 未知的服务名称 '$service'${NC}"
                    echo "使用 'backend' 或 'agent'"
                    exit 1
                fi
                show_status "$svc"
            fi
            ;;
        logs|log)
            if [ "$service" = "all" ] || [ -z "$service" ]; then
                echo -e "${YELLOW}请指定服务名称 (backend 或 agent)${NC}"
                echo "示例: $0 logs backend"
                exit 1
            fi
            local svc=$(get_service_name "$service")
            if [ -z "$svc" ]; then
                echo -e "${RED}错误: 未知的服务名称 '$service'${NC}"
                exit 1
            fi
            if [ "$3" = "-f" ] || [ "$3" = "--follow" ]; then
                show_logs_follow "$service"
            else
                show_logs "$service" "${3:-50}"
            fi
            ;;
        restart)
            if [ "$service" = "all" ]; then
                restart_service
            else
                local svc=$(get_service_name "$service")
                if [ -z "$svc" ]; then
                    echo -e "${RED}错误: 未知的服务名称 '$service'${NC}"
                    exit 1
                fi
                restart_service "$svc"
            fi
            ;;
        start)
            if [ "$service" = "all" ]; then
                start_service
            else
                local svc=$(get_service_name "$service")
                if [ -z "$svc" ]; then
                    echo -e "${RED}错误: 未知的服务名称 '$service'${NC}"
                    exit 1
                fi
                start_service "$svc"
            fi
            ;;
        stop)
            if [ "$service" = "all" ]; then
                stop_service
            else
                local svc=$(get_service_name "$service")
                if [ -z "$svc" ]; then
                    echo -e "${RED}错误: 未知的服务名称 '$service'${NC}"
                    exit 1
                fi
                stop_service "$svc"
            fi
            ;;
        enable)
            if [ "$service" = "all" ]; then
                enable_service
            else
                local svc=$(get_service_name "$service")
                if [ -z "$svc" ]; then
                    echo -e "${RED}错误: 未知的服务名称 '$service'${NC}"
                    exit 1
                fi
                enable_service "$svc"
            fi
            ;;
        disable)
            if [ "$service" = "all" ]; then
                disable_service
            else
                local svc=$(get_service_name "$service")
                if [ -z "$svc" ]; then
                    echo -e "${RED}错误: 未知的服务名称 '$service'${NC}"
                    exit 1
                fi
                disable_service "$svc"
            fi
            ;;
        health|check)
            check_health
            ;;
        info)
            if [ "$service" = "all" ]; then
                show_info
            else
                local svc=$(get_service_name "$service")
                if [ -z "$svc" ]; then
                    echo -e "${RED}错误: 未知的服务名称 '$service'${NC}"
                    exit 1
                fi
                show_info "$svc"
            fi
            ;;
        ports)
            check_ports
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}错误: 未知的命令 '$command'${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"

