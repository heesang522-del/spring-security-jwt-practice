(function () {
    const roomId = Number(new URLSearchParams(location.search).get("roomId") || 1);
    const currentMemberId = loginMemberId;

    const form = document.querySelector("[data-message-form]");
    const input = document.querySelector("[data-message-input]");
    const messageList = document.querySelector("[data-message-list]");
    const roomsPanel = document.querySelector("[data-rooms-panel]");
    const roomsToggle = document.querySelector("[data-rooms-toggle]");
    const roomButtons = document.querySelectorAll("[data-room-item]");
    const roomTitle = document.querySelector("[data-room-title]");
    const roomSearch = document.querySelector("#room-search");
    const emptyMessage = document.querySelector("#empty-room-message");
    const roomCount = document.querySelector("#room-count");
    const leaveButtons = document.querySelectorAll(".leave-room-btn");
    const joinRoomButton = document.querySelector("#join-room-btn");
    const editRoomButton = document.querySelector("#edit-room-btn");
    const editRoomModal = document.querySelector("#edit-room-modal");
    const editRoomCancel = document.querySelector("#edit-room-cancel");
    const editRoomSave = document.querySelector("#edit-room-save");
    const editRoomName = document.querySelector("#edit-room-name");
    const editRoomDescription = document.querySelector("#edit-room-description");
    const editRoomTheme = document.querySelector("#edit-room-theme");
    const editRoomType = document.querySelector("#edit-room-type");
    const editTargetLabel = document.querySelector("#edit-target-label");
    const editTargetId = document.querySelector("#edit-target-id");
    const editRoomImage = document.querySelector("#edit-room-image");
    const roomMenuButton = document.querySelector("#room-menu-button");
    const roomMenu = document.querySelector("#room-menu");

    if (roomMenuButton && roomMenu) {
        function closeRoomMenu() {
            roomMenu.classList.remove("show");
            roomMenuButton.setAttribute("aria-expanded", "false");
        }

        roomMenuButton.addEventListener("click", function (event) {
            event.stopPropagation();
            const isOpen = roomMenu.classList.toggle("show");
            roomMenuButton.setAttribute("aria-expanded", String(isOpen));
        });

        document.addEventListener("click", function (event) {
            if (!roomMenu.contains(event.target) && !roomMenuButton.contains(event.target)) {
                closeRoomMenu();
            }
        });

        document.addEventListener("keydown", function (event) {
            if (event.key === "Escape") {
                closeRoomMenu();
                if (editRoomModal) editRoomModal.classList.remove("show");
                const reportModal = document.querySelector("#report-modal");
                if (reportModal) reportModal.style.display = "none";
            }
        });
    }

    let stompClient = null;
    let isConnected = false;

    if (roomSearch) {
        roomSearch.addEventListener("input", function () {
            const keyword = roomSearch.value.trim().toLowerCase();
            let count = 0;

            roomButtons.forEach(function (button) {
                const wrapper = button.closest(".room-item-wrapper");
                const roomName = button.dataset.roomName.toLowerCase();

                if (roomName.includes(keyword)) {
                    wrapper.style.display = "flex";
                    count++;
                } else {
                    wrapper.style.display = "none";
                }
            });

            if (emptyMessage) {
                if (keyword !== "" && count === 0) {
                    emptyMessage.style.display = "block";
                } else {
                    emptyMessage.style.display = "none";
                }
            }
        });
    }

    function formatTime(date) {
        return new Intl.DateTimeFormat("ko-KR", {
            hour: "2-digit",
            minute: "2-digit",
            hour12: false
        }).format(date);
    }

    function addMessage(data) {
        if (document.querySelector(`[data-message-id="${data.messageId}"]`)) {
            return;
        }

        const message = document.createElement("div");
        message.className = data.memberId === currentMemberId
            ? "message my-message"
            : "message other-message";

        message.dataset.messageId = data.messageId;

        message.innerHTML = `
            ${data.memberId !== currentMemberId ? '<span class="message__avatar"></span>' : ''}
            <div class="message__body">
                ${data.memberId !== currentMemberId ? `<span class="message__author">${data.nickname}</span>` : ''}
                <div class="message__bubble">
                    ${data.message}
                </div>
            </div>
            <div>
                <time class="message__time">
                    ${formatTime(new Date(data.sentAt || Date.now()))}
                </time>
               ${data.memberId === currentMemberId
            ? `<div class="message-read" data-message-id="${data.messageId}">
                    ${data.unreadCount === 0 ? "읽음" : data.unreadCount}
               </div>`
            : ""
        }
            </div>
        `;

        messageList.appendChild(message);
        messageList.scrollTop = messageList.scrollHeight;

        if (data.memberId !== currentMemberId) {
            updateReadMessage();
        }
    }

    function connectSocket() {
        stompClient = new StompJs.Client({
            webSocketFactory: () => new SockJS("/chat"),
            reconnectDelay: 5000,
            onConnect: function () {
                isConnected = true;

                stompClient.subscribe("/topic/chat/" + roomId, function (message) {
                    const data = JSON.parse(message.body);
                    addMessage(data);
                });

                stompClient.subscribe("/topic/read/" + roomId, function (message) {
                    const list = JSON.parse(message.body);
                    updateReadCount(list);
                });

                stompClient.subscribe("/topic/member/" + roomId, function (message) {
                    const members = JSON.parse(message.body);
                    renderMembers(members);
                });

                stompClient.subscribe("/topic/room/delete/" + roomId, function (message) {
                    alert("채팅방이 삭제되었습니다.");
                    location.replace("/index");
                });

                stompClient.publish({
                    destination: "/app/member/join",
                    body: JSON.stringify({ roomId: Number(roomId) })
                });

                // 접속하자마자 현재 마지막 메시지 읽음 처리 전송
                setTimeout(function () {
                    updateReadMessage();
                }, 200);
            },
            onStompError: function (frame) {
                console.error("STOMP ERROR", frame);
            },
            onWebSocketError: function (error) {
                console.error("SOCKET ERROR", error);
            }
        });
        stompClient.activate();
    }

    if (form && input && messageList) {
        form.addEventListener("submit", function (event) {
            event.preventDefault();
            const text = input.value.trim();

            if (!text) return;

            const data = {
                roomId: Number(roomId),
                memberId: currentMemberId,
                message: text
            };

            if (!isConnected) {
                alert("서버와 아직 연결되지 않았습니다.");
                return;
            }

            stompClient.publish({
                destination: "/app/message",
                body: JSON.stringify(data)
            });

            input.value = "";
            input.style.height = "";
        });

        input.addEventListener("keydown", function (event) {
            if (event.key === "Enter" && !event.shiftKey) {
                event.preventDefault();
                form.requestSubmit();
            }
        });

        input.addEventListener("input", function () {
            input.style.height = "auto";
            input.style.height = Math.min(input.scrollHeight, 110) + "px";
        });
    }

    if (roomsToggle && roomsPanel) {
        roomsToggle.addEventListener("click", function () {
            const isOpen = roomsPanel.classList.toggle("is-open");
            roomsToggle.setAttribute("aria-expanded", String(isOpen));
        });
    }

    roomButtons.forEach(function (button) {
        button.addEventListener("click", function () {
            roomButtons.forEach(function (item) {
                item.classList.remove("is-active");
            });
            button.classList.add("is-active");
            if (roomTitle) {
                roomTitle.textContent = button.dataset.roomName;
            }
            if (roomsPanel) {
                roomsPanel.classList.remove("is-open");
            }
        });
    });

    leaveButtons.forEach(function(button){
        button.addEventListener("click", async function(event){
            event.preventDefault();

            if(!confirm("채팅방에서 나가시겠습니까?")){
                return;
            }

            const targetRoomId = Number(button.dataset.roomId);
            const response = await fetch("/chat/room/leave",{
                method: "POST",
                headers: {"Content-Type": "application/json"},
                body: JSON.stringify({
                    roomId: targetRoomId,
                    memberId: currentMemberId
                })
            });

            if(!response.ok){
                alert("채팅방 나가기에 실패했습니다.");
                return;
            }

            if (stompClient && isConnected) {
                stompClient.publish({
                    destination: "/app/member/leave",
                    body: JSON.stringify({ roomId: targetRoomId })
                });
            }

            const roomItem = button.closest(".room-item-wrapper");
            roomItem.remove();
            updateRoomCount();

            if(roomId === targetRoomId){
                location.replace("/index");
            }
        });
    });

    function updateRoomCount(){
        const count = document.querySelectorAll(".room-item-wrapper").length;
        if(roomCount){
            roomCount.textContent = "가입한 대화방 " + count;
        }
    }

    if (joinRoomButton && !joinRoomButton.disabled) {
        joinRoomButton.addEventListener("click", async function () {
            if (!confirm("나의 대화방에 추가하시겠습니까?")) return;

            const response = await fetch("/chat/room/join", {
                method: "POST",
                headers: {"Content-Type": "application/json"},
                body: JSON.stringify({ roomId: roomId })
            });

            if (!response.ok) {
                alert("가입 실패");
                return;
            }

            const joinResult = await response.json();
            if (joinResult) {
                alert("가입되었습니다.");
                location.href = "/chatroom?roomId=" + roomId;
            } else {
                alert("이미 가입한 채팅방입니다.");
            }
        });
    }

    if (editRoomButton && editRoomModal) {
        editRoomButton.addEventListener("click", async function () {
            editRoomModal.classList.add("show");
            await loadEditTarget();
        });
    }

    async function loadEditTarget() {
        if (!editRoomType || !editTargetId) return;
        const roomType = editRoomType.value;
        editTargetId.innerHTML = `<option value="">선택해주세요</option>`;

        if (roomType === "artist") {
            editTargetLabel.textContent = "아티스트 선택";
            const response = await fetch("/chat/artist/list");
            const artists = await response.json();
            artists.forEach(function (artist) {
                const option = document.createElement("option");
                option.value = artist.artistId;
                option.textContent = artist.artistName;
                editTargetId.appendChild(option);
            });
        } else if (roomType === "song") {
            editTargetLabel.textContent = "노래 선택";
            const response = await fetch("/chat/song/list");
            const songs = await response.json();
            songs.forEach(function (song) {
                const option = document.createElement("option");
                option.value = song.songId;
                option.textContent = song.songTitle;
                editTargetId.appendChild(option);
            });
        }

        const response = await fetch("/chat/room/" + roomId);
        const room = await response.json();
        if (room.roomType === roomType) {
            editTargetId.value = room.targetId;
        }
    }

    if (editRoomType) {
        editRoomType.addEventListener("change", function () {
            loadEditTarget();
        });
    }

    if(editRoomCancel) {
        editRoomCancel.addEventListener("click", function (){
            editRoomModal.classList.remove("show");
        });
    }

    if(editRoomModal) {
        editRoomModal.addEventListener("click", function (event){
            if(event.target === editRoomModal) {
                editRoomModal.classList.remove("show");
            }
        });
    }

    if (editRoomSave) {
        editRoomSave.addEventListener("click", async function () {
            const roomName = editRoomName.value.trim();
            const roomDescription = editRoomDescription.value.trim();
            const roomType = editRoomType.value;
            const targetId = Number(editTargetId.value);
            const themeId = Number(editRoomTheme.value);

            if (!roomName) { alert("채팅방 이름을 입력해주세요."); return; }
            if (!roomDescription) { alert("방 설명을 입력해주세요."); return; }
            if (!targetId) { alert("아티스트 또는 노래를 선택해주세요."); return; }
            if (!themeId) { alert("장르를 선택해주세요."); return; }

            const data = {
                roomId: roomId,
                roomName: roomName,
                roomDescription: roomDescription,
                roomType: roomType,
                targetId: targetId,
                themeId: themeId
            };

            const formData = new FormData();
            formData.append("room", new Blob([JSON.stringify(data)], {type: "application/json"}));

            const imageFile = editRoomImage.files[0];
            if (imageFile) {
                formData.append("image", imageFile);
            }

            const response = await fetch("/chat/room/update", {
                method: "POST",
                body: formData
            });

            if (!response.ok) {
                const message = await response.text();
                alert(message || "채팅방 수정에 실패했습니다.");
                return;
            }
            alert("채팅방이 수정되었습니다.");
            location.reload();
        });
    }

    document.querySelectorAll(".message__time").forEach(function(time){
        const value = time.dataset.time;
        if(!value) return;
        time.textContent = formatTime(new Date(value));
    });

    if(roomId) {
        connectSocket();
    }

    function renderMembers(members) {
        const onlineList = document.querySelector("#online-member-list");
        const offlineList = document.querySelector("#offline-member-list");
        const memberCount = document.querySelector("#member-count");
        const roomMemberCount = document.querySelector("#room-member-count");

        if (!onlineList || !offlineList) return;

        onlineList.innerHTML = "";
        offlineList.innerHTML = "";

        let onlineCount = 0;

        members.sort(function(a, b) {
            if (a.memberId === roomOwnerId) return -1;
            if (b.memberId === roomOwnerId) return 1;
            return 0;
        });

        members.forEach(function(member) {
            let ownerText = member.memberId === roomOwnerId ? `<span style="color: blue; font-weight: bold;">[방장]</span>` : "";
            let reportButton = member.memberId !== currentMemberId
                ? `<button type="button" onclick="reportMember(${member.memberId})" style="margin-left:auto; font-size:11px;">신고</button>`
                : "";

            const html = `
                <div class="member-item">
                    <span class="avatar">${member.nickname.substring(0, 1)}</span>
                    <span>
                        <strong class="member-item__name">${member.nickname}</strong>
                        ${ownerText}
                        <span class="member-item__status">
                            ${member.online ? "🟢 참여중" : "⚪ 오프라인"}
                        </span>
                    </span>
                    ${reportButton}
                </div>
            `;

            if (member.online) {
                onlineCount++;
                onlineList.innerHTML += html;
            } else {
                offlineList.innerHTML += html;
            }
        });

        // 우측 패널 참여자 수 (예: "2명")
        if (memberCount) memberCount.textContent = onlineCount + "명";

        // 상단 헤더 참여 중 문구 (예: "2명 참여 중")
        if (roomMemberCount) roomMemberCount.textContent = onlineCount + "명 참여 중";
    }
    document.querySelectorAll("input[name='reportReason']").forEach(function(radio) {
        radio.addEventListener("change", function() {
            const etcInput = document.querySelector("#report-etc");
            if (this.value === "기타") {
                etcInput.style.display = "block";
            } else {
                etcInput.style.display = "none";
                etcInput.value = "";
            }
        });
    });

    document.querySelector("#report-cancel").addEventListener("click", function() {
        closeReportModal();
    });

    document.querySelector("#report-submit").addEventListener("click", async function() {
        const selectedReason = document.querySelector("input[name='reportReason']:checked");
        if (!selectedReason) {
            alert("신고 사유를 선택해주세요.");
            return;
        }

        let reason = selectedReason.value;
        if (reason === "기타") {
            const etcReason = document.querySelector("#report-etc").value.trim();
            if (!etcReason) {
                alert("기타 신고 사유를 입력해주세요.");
                return;
            }
            reason = "기타: " + etcReason;
        }

        const response = await fetch("/chat/report", {
            method: "POST",
            headers: {"Content-Type": "application/json"},
            body: JSON.stringify({
                roomId: Number(roomId),
                reportedId: selectedReportedId,
                reason: reason
            })
        });

        if (response.ok) {
            alert("신고가 접수되었습니다.");
            closeReportModal();
        } else {
            const message = await response.text();
            alert(message || "신고 처리에 실패했습니다.");
        }
    });

    function closeReportModal() {
        const modal = document.querySelector("#report-modal");
        modal.style.display = "none";
        selectedReportedId = null;
        document.querySelectorAll("input[name='reportReason']").forEach(r => r.checked = false);
        const etcInput = document.querySelector("#report-etc");
        etcInput.value = "";
        etcInput.style.display = "none";
    }

    function updateReadMessage(){
        const messages = messageList.querySelectorAll("[data-message-id]");
        const lastMessage = messages[messages.length - 1];

        if (stompClient && isConnected) {
            stompClient.publish({
                destination: "/app/message/read",
                body: JSON.stringify({
                    roomId: Number(roomId),
                    lastReadMessageId: lastMessage ? Number(lastMessage.dataset.messageId) : 0
                })
            });
        }
    }
    function updateReadCount(list){
        list.forEach(function(message){
            const item = document.querySelector('.message-read[data-message-id="' + message.messageId + '"]');
            if(!item) return;

            if(message.unreadCount === 0){
                item.innerText = "읽음";
            }else{
                item.innerText = message.unreadCount;
            }
        });
    }
})();