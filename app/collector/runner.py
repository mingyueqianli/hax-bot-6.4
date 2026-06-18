from __future__ import annotations

import logging
import signal
import sys
import time
from threading import Event

from app import config
from app.collector.hax import fetch_snapshot, save_snapshot


def setup_logging() -> None:
    config.ensure_runtime_dirs()
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)],
    )


def main() -> None:
    setup_logging()
    logger = logging.getLogger("hax.collector")
    stop_event = Event()

    def _stop(signum, frame):  # noqa: ANN001
        logger.info("收到退出信号 %s，准备停止采集...", signum)
        stop_event.set()

    signal.signal(signal.SIGTERM, _stop)
    signal.signal(signal.SIGINT, _stop)

    interval = config.get_interval_seconds()
    logger.info("HAX Collector 启动，采集间隔：%s 秒", interval)
    while not stop_event.is_set():
        try:
            snapshot = fetch_snapshot()
            if snapshot:
                save_snapshot(snapshot)
                logger.info(
                    "采集成功：总数=%s，数据中心=%s 个",
                    snapshot.get("total"),
                    len(snapshot.get("centers") or {}),
                )
            else:
                logger.warning("本次采集无有效数据，保留旧文件")
        except Exception as exc:  # noqa: BLE001
            logger.exception("采集失败：%s", exc)

        for _ in range(interval):
            if stop_event.is_set():
                break
            time.sleep(1)

    logger.info("HAX Collector 已停止")


if __name__ == "__main__":
    main()
