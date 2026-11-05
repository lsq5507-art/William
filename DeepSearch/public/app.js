/**
 * DeepSearch DEV-02 · D-02b client (mock probe)
 * ZH · Narrative B · Preview·不会扣款 · no Stripe · no lp.*
 */
(function () {
  "use strict";

  const form = document.getElementById("searchForm");
  const input = document.getElementById("handle");
  const field = document.getElementById("searchField");
  const err = document.getElementById("fieldError");
  const searchBtn = document.getElementById("searchBtn");
  const results = document.getElementById("results");
  const rowsEl = document.getElementById("resultRows");
  const statusEl = document.getElementById("scanStatus");
  const actions = document.getElementById("resultActions");
  const sampleBadge = document.getElementById("sampleBadge");
  const toast = document.getElementById("toast");
  const overlay = document.getElementById("gateOverlay");
  const menuBtn = document.getElementById("menuBtn");
  const navMobile = document.getElementById("navMobile");
  const cancelBtn = document.getElementById("cancelBtn");

  let scanTimer = null;
  let cancelled = false;
  let isSample = false;
  let scanning = false;
  let toastTimer = null;

  const PLATFORMS = [
    { id: "x", name: "X (Twitter)", url: (h) => "https://x.com/" + h },
    { id: "ig", name: "Instagram", url: (h) => "https://www.instagram.com/" + h + "/" },
    { id: "gh", name: "GitHub", url: (h) => "https://github.com/" + h },
    { id: "rd", name: "Reddit", url: (h) => "https://www.reddit.com/user/" + h },
    { id: "yt", name: "YouTube", url: (h) => "https://www.youtube.com/@" + h },
    { id: "tt", name: "TikTok", url: (h) => "https://www.tiktok.com/@" + h },
  ];

  const SAMPLE_OUTCOMES = {
    elonmusk: ["found", "found", "found", "clear", "found", "uncertain"],
    nasa: ["found", "found", "found", "found", "found", "clear"],
    wikipedia: ["clear", "clear", "found", "found", "uncertain", "clear"],
  };

  function showToast(msg) {
    toast.textContent = msg;
    toast.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      toast.classList.remove("show");
    }, 2800);
  }

  function setError(msg) {
    if (msg) {
      err.textContent = msg;
      err.classList.add("show");
      field.classList.add("is-error");
      input.setAttribute("aria-invalid", "true");
    } else {
      err.textContent = "";
      err.classList.remove("show");
      field.classList.remove("is-error");
      input.setAttribute("aria-invalid", "false");
    }
  }

  function validate(v) {
    if (!v || !v.trim()) return "请输入要查询的用户名。";
    if (!/^[A-Za-z0-9_.]+$/.test(v.trim())) {
      return "请使用字母、数字、下划线或英文句点。";
    }
    return null;
  }

  function outcomeFor(handle, i) {
    const key = handle.toLowerCase();
    if (SAMPLE_OUTCOMES[key]) return SAMPLE_OUTCOMES[key][i] || "clear";
    const seq = ["found", "clear", "found", "uncertain", "clear", "found"];
    return seq[i % seq.length];
  }

  function setScanningUI(on) {
    scanning = on;
    searchBtn.disabled = on;
    searchBtn.textContent = on ? "查看中…" : "搜一下";
    cancelBtn.hidden = !on;
  }

  function renderLoading(handle) {
    results.hidden = false;
    actions.hidden = false;
    sampleBadge.hidden = !isSample;
    statusEl.dataset.state = "scanning";
    statusEl.textContent = "正在查看 @" + handle + " 的公开主页…";
    rowsEl.setAttribute("aria-busy", "true");
    setScanningUI(true);
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    rowsEl.innerHTML = PLATFORMS.map(function (p, i) {
      const delay = reduce ? 0 : i * 40;
      return (
        '<li class="row enter" style="animation-delay:' +
        delay +
        'ms">' +
        '<span class="dot dot-loading" aria-hidden="true"></span>' +
        '<div class="row-main"><div class="plat">' +
        p.name +
        '</div><div class="meta">查看中…</div></div>' +
        '<span class="row-state">查看中…</span></li>'
      );
    }).join("");
    results.scrollIntoView({
      behavior: reduce ? "auto" : "smooth",
      block: "start",
    });
  }

  function finalize(handle) {
    if (cancelled) return;
    statusEl.dataset.state = "done";
    statusEl.textContent = isSample
      ? "样例完成 · @" + handle
      : "完成 · @" + handle;
    rowsEl.setAttribute("aria-busy", "false");
    setScanningUI(false);
    cancelBtn.hidden = true;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    rowsEl.innerHTML = PLATFORMS.map(function (p, i) {
      const o = outcomeFor(handle, i);
      const label =
        o === "found" ? "找到" : o === "uncertain" ? "不确定" : "未找到";
      const cls =
        o === "found" ? "found" : o === "uncertain" ? "uncertain" : "clear";
      const open =
        o === "found"
          ? '<a class="row-action" href="' +
            p.url(handle) +
            '" target="_blank" rel="noopener noreferrer">打开 ↗</a>'
          : "";
      const delay = reduce ? 0 : i * 50;
      return (
        '<li class="row enter" style="animation-delay:' +
        delay +
        'ms">' +
        '<span class="dot dot-' +
        o +
        '" aria-hidden="true"></span>' +
        '<div class="row-main"><div class="plat">' +
        p.name +
        '</div><div class="meta">@' +
        handle +
        "</div></div>" +
        '<span class="row-state ' +
        cls +
        '">' +
        label +
        "</span>" +
        open +
        "</li>"
      );
    }).join("");
    actions.hidden = false;
  }

  function runScan(handle, sample) {
    cancelled = false;
    isSample = !!sample;
    clearTimeout(scanTimer);
    setError(null);
    renderLoading(handle);
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    scanTimer = setTimeout(function () {
      finalize(handle);
    }, reduce ? 80 : 1400);
  }

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    if (scanning) return;
    const v = input.value.replace(/^@/, "").trim();
    const msg = validate(v);
    if (msg) {
      setError(msg);
      input.focus();
      return;
    }
    runScan(v, false);
  });

  document.querySelectorAll(".chip").forEach(function (btn) {
    btn.addEventListener("click", function () {
      if (scanning) return;
      const h = btn.getAttribute("data-handle");
      input.value = h;
      setError(null);
      runScan(h, true);
    });
  });

  document.querySelectorAll(".pill").forEach(function (btn) {
    btn.addEventListener("click", function () {
      document.querySelectorAll(".pill").forEach(function (p) {
        p.setAttribute("aria-pressed", "false");
      });
      btn.setAttribute("aria-pressed", "true");
      const copy = document.getElementById("sceneCopy");
      copy.textContent =
        btn.getAttribute("data-scene") === "dating"
          ? "见面前往公开足迹，降低信息不对称。"
          : "新联系人、卖家或合租对象 — 先查公开用户名。";
    });
  });

  function openGate() {
    overlay.hidden = false;
    overlay.classList.add("open");
    document.getElementById("gatePrimary").focus();
  }

  function closeGate() {
    overlay.classList.remove("open");
    overlay.hidden = true;
  }

  document.getElementById("exportBtn").addEventListener("click", openGate);
  document.getElementById("gatePrimary").addEventListener("click", function () {
    closeGate();
    document.getElementById("pricing").scrollIntoView({ behavior: "smooth" });
  });
  document.getElementById("gateSecondary").addEventListener("click", function () {
    closeGate();
    /* G-01: 暂不 = close only, no entitlement */
  });
  overlay.addEventListener("click", function (e) {
    if (e.target === overlay) closeGate();
  });
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && overlay.classList.contains("open")) closeGate();
  });

  document.getElementById("retryBtn").addEventListener("click", function () {
    if (scanning) return;
    const v = input.value.replace(/^@/, "").trim() || "elonmusk";
    runScan(v, isSample);
  });

  cancelBtn.addEventListener("click", function () {
    if (!scanning) return;
    cancelled = true;
    clearTimeout(scanTimer);
    statusEl.dataset.state = "idle";
    statusEl.textContent = "已取消";
    rowsEl.setAttribute("aria-busy", "false");
    setScanningUI(false);
    cancelBtn.hidden = true;
    actions.hidden = false;
    showToast("已取消本次查看");
  });

  document.getElementById("runMineBtn").addEventListener("click", function () {
    showToast("账户 / 套餐占位 — 不会扣款");
  });

  document.querySelectorAll(".price-cta").forEach(function (btn) {
    btn.addEventListener("click", function () {
      showToast("这是预览壳，不会扣款。");
    });
  });

  if (menuBtn && navMobile) {
    menuBtn.addEventListener("click", function () {
      const open = navMobile.classList.toggle("open");
      navMobile.hidden = !open;
      menuBtn.setAttribute("aria-expanded", open ? "true" : "false");
    });
    navMobile.querySelectorAll("a").forEach(function (a) {
      a.addEventListener("click", function () {
        navMobile.classList.remove("open");
        navMobile.hidden = true;
        menuBtn.setAttribute("aria-expanded", "false");
      });
    });
  }
})();
