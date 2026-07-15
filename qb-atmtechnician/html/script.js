const tablet = document.getElementById('tablet');
const closeBtn = document.getElementById('closeBtn');
const takeJobBtn = document.getElementById('takeJobBtn');

window.addEventListener('message', (event) => {
    const { action, data } = event.data;

    if (action === 'openTablet') {
        tablet.classList.remove('hidden');
        populateTablet(data);
    }

    if (action === 'updateTablet') {
        populateTablet(data);
    }

    if (action === 'closeTablet') {
        tablet.classList.add('hidden');
    }
});

function populateTablet(data) {
    if (!data) return;

    document.getElementById('profileName').innerText = data.name || '-';
    document.getElementById('profileGrade').innerText = 'Grade: ' + (data.grade || '-');
    document.getElementById('profileStatus').innerText = data.onDuty ? '🟢 ON DUTY' : '🔴 OFF DUTY';

    const g = data.gradeInfo;
    if (g) {
        document.getElementById('profileGrade').innerText = 'Grade: ' + g.gradeName;

        const xpFill = document.getElementById('xpBarFill');
        const xpText = document.getElementById('xpText');
        const xpNext = document.getElementById('xpNextGrade');

        const current = g.currentXP || 0;
        const floor = g.xpForCurrentGrade || 0;
        const ceiling = g.xpForNextGrade || floor || 1;

        xpText.innerText = `${current.toLocaleString()} / ${ceiling.toLocaleString()} XP`;

        if (g.isMaxGrade) {
            xpNext.innerText = 'MAX GRADE';
            xpFill.classList.add('maxed');
            xpFill.style.width = '100%';
        } else {
            xpFill.classList.remove('maxed');
            const span = Math.max(1, ceiling - floor);
            const progressed = Math.min(Math.max(current - floor, 0), span);
            xpFill.style.width = (progressed / span * 100) + '%';
            xpNext.innerText = '';
        }
    }

    document.getElementById('totalJobs').innerText = data.totalJobs || 0;
    document.getElementById('successJobs').innerText = data.successfulJobs || 0;
    document.getElementById('totalEarned').innerText = '$' + (data.totalEarned || 0);

    const recentList = document.getElementById('recentJobs');
    recentList.innerHTML = '';
    (data.recentJobs || []).forEach((job) => {
        const div = document.createElement('div');
        div.className = 'recent-item ' + (job.success ? 'success' : 'fail');
        div.innerHTML = `
            <span>${job.label || job.atm_id}</span>
            <span>${job.success ? '✅ $' + job.payout : '❌ Failed'}</span>
        `;
        recentList.appendChild(div);
    });

    const atmList = document.getElementById('atmList');
    atmList.innerHTML = '';
    (data.atmLocations || []).forEach((loc, i) => {
        const div = document.createElement('div');
        div.innerText = `#${i + 1}  ${loc.label}`;
        atmList.appendChild(div);
    });
    document.getElementById('atmCount').innerText = (data.atmLocations || []).length;

    const bankMoney = data.bankMoney || 0;
    document.getElementById('bankMoney').innerText = '$' + bankMoney;

    const shiftBanner = document.getElementById('shiftBanner');
    if (data.shiftCooldown && data.shiftCooldown > 0) {
        shiftBanner.classList.remove('hidden');
        shiftBanner.innerHTML = `<span>⏳ Shift cooldown</span><span>${data.shiftCooldown} min left</span>`;
    } else {
        shiftBanner.classList.add('hidden');
    }

    const shopList = document.getElementById('shopList');
    shopList.innerHTML = '';
    (data.shopItems || []).forEach((entry) => {
        const canAfford = bankMoney >= entry.price;

        const row = document.createElement('div');
        row.className = 'shop-item';
        row.innerHTML = `
            <div class="shop-item-info">
                <span class="shop-item-name">${entry.label}</span>
                <span class="shop-item-price">$${entry.price}</span>
            </div>
            <button class="shop-buy-btn" data-item="${entry.item}" ${canAfford ? '' : 'disabled'}>Buy</button>
        `;
        shopList.appendChild(row);
    });

    shopList.querySelectorAll('.shop-buy-btn').forEach((btn) => {
        btn.addEventListener('click', () => {
            const itemName = btn.getAttribute('data-item');
            btn.disabled = true;
            btn.innerText = '...';

            fetch(`https://${getResourceName()}/buyItem`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ item: itemName }),
            });
        });
    });
}

function getResourceName() {
    return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'qb-atmtechnician';
}

closeBtn.addEventListener('click', () => {
    tablet.classList.add('hidden');
    fetch(`https://${getResourceName()}/closeTablet`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    });
});

takeJobBtn.addEventListener('click', () => {
    takeJobBtn.disabled = true;
    takeJobBtn.innerText = 'Getting van...';

    fetch(`https://${getResourceName()}/takeJob`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    })
        .then(() => {
            tablet.classList.add('hidden');
        })
        .finally(() => {
            takeJobBtn.disabled = false;
            takeJobBtn.innerText = '🚐 Take Job (Get Van + Mark Location)';
        });
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        tablet.classList.add('hidden');
        fetch(`https://${getResourceName()}/closeTablet`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({}),
        });
    }
});
