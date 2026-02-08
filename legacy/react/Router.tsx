
import React, { useState, useEffect } from 'react';
import UserApp from './apps/user-app/App';
import AdminApp from './apps/admin-app/AdminApp';
import EmployerApp from './apps/employer-app/App';
import { Login } from './components/Login';
import { Authentication } from './components/Authentication';
import { AdminLogin } from './apps/admin-app/components/AdminLogin';
import { ADMIN_USERS_DATA } from './apps/admin-app/data/adminUsers';
import { AdminUser } from './apps/admin-app/types';

type View = 'landing' | 'user' | 'admin' | 'employer';
type Role = 'user' | 'employer';

interface StoredUser {
    phone: string;
    name: string;
}

interface StoredEmployer {
    phone: string;
    name: string;
    companyName: string;
    isRegistered: boolean;
}

const Router: React.FC = () => {
    const [view, setView] = useState<View>('landing');
    const [activeRole, setActiveRole] = useState<Role>('user');
    const [authStep, setAuthStep] = useState<'login' | 'verify'>('login');
    const [phoneToVerify, setPhoneToVerify] = useState<string | null>(null);
    const [authRole, setAuthRole] = useState<Role | null>(null);
    const [rememberMe, setRememberMe] = useState(true);
    const [adminUsers, setAdminUsers] = useState<AdminUser[]>(ADMIN_USERS_DATA);
    const [isAdminPanelOpen, setIsAdminPanelOpen] = useState(false);

    useEffect(() => {
        try {
            // --- SEED WORKERS (USERS) ---
            const registeredUsersRaw = localStorage.getItem('registeredUsers');
            let currentUsers = registeredUsersRaw ? JSON.parse(registeredUsersRaw) : [];
            const userProfilesRaw = localStorage.getItem('userProfiles');
            let currentProfiles = userProfilesRaw ? JSON.parse(userProfilesRaw) : {};
            const TEST_USER_PHONE = '01011112222';

            // Seed if only default user or fewer exists
            if (currentUsers.length <= 1) {
                // 1. Ensure Default Test User
                if (!currentUsers.find((u: any) => u.phone === TEST_USER_PHONE)) {
                    currentUsers.push({ phone: TEST_USER_PHONE, name: '김테스트' });
                    currentProfiles[TEST_USER_PHONE] = {
                        name: '김테스트',
                        rrn: '900101-1234567',
                        gender: 'male',
                        nationality: 'korean',
                        phone: TEST_USER_PHONE,
                        preferredAreas: ['서울 강남구'],
                        bank: 'KB국민은행',
                        accountNumber: '111-222-333444',
                        accountHolder: '김테스트',
                        signatureDataUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=', 
                        bankAccountFileName: '통장사본.jpg',
                        idCardFileName: '신분증.jpg',
                        safetyCertFileName: '이수증.jpg',
                        profilePictureFileName: '프로필사진.jpg',
                        registrationDate: '2024-07-20T09:00:00.000Z',
                    };
                }

                // 2. Generate 10 Mock Workers
                const WORKER_NAMES = ['이철수', '박지영', '최민호', '정수빈', '강현우', '조은지', '윤성민', '장미란', '임재범', '한예슬'];
                const AREAS = ['서울 강남구', '서울 마포구', '경기 성남시', '경기 수원시', '인천 부평구'];
                
                WORKER_NAMES.forEach((name, index) => {
                    const phone = `0108000${String(index).padStart(4, '0')}`;
                    if (!currentUsers.find((u: any) => u.phone === phone)) {
                        const isMale = index % 2 === 0;
                        const birthYear = 80 + index; 
                        const genderDigit = isMale ? '1' : '2';
                        
                        currentUsers.push({ phone, name });
                        currentProfiles[phone] = {
                            name,
                            rrn: `${birthYear}0101-${genderDigit}******`,
                            gender: isMale ? 'male' : 'female',
                            nationality: 'korean',
                            phone,
                            preferredAreas: [AREAS[index % AREAS.length]],
                            bank: '신한은행',
                            accountNumber: `110-${index}${index}${index}-123456`,
                            accountHolder: name,
                            signatureDataUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
                            bankAccountFileName: 'sample_bank.jpg',
                            idCardFileName: 'sample_id.jpg',
                            safetyCertFileName: 'sample_cert.jpg',
                            registrationDate: `2024-08-${String(index + 1).padStart(2, '0')}T10:${String(index*5).padStart(2,'0')}:00.000Z`,
                        };
                    }
                });
                localStorage.setItem('registeredUsers', JSON.stringify(currentUsers));
                localStorage.setItem('userProfiles', JSON.stringify(currentProfiles));
            }

            // --- SEED EMPLOYERS ---
            const employersRaw = localStorage.getItem('employers');
            let currentEmployers = employersRaw ? JSON.parse(employersRaw) : [];
            const TEST_EMPLOYER_PHONE = '01099998888';

            if (currentEmployers.length <= 1) {
                if (!currentEmployers.find((e: any) => e.phone === TEST_EMPLOYER_PHONE)) {
                    currentEmployers.push({
                        phone: TEST_EMPLOYER_PHONE,
                        name: '박소장',
                        companyName: '튼튼건설',
                        isRegistered: true
                    });
                }

                const EMPLOYER_NAMES = ['김대표', '이팀장', '최부장', '정소장', '강실장', '조반장', '윤이사', '장사장', '임전무', '한상무'];
                const COMPANIES = ['대박건설', '미래건축', '성실인테리어', '제일설비', '하늘공영', '바른시공', '태양전기', '푸른조경', '한마음종합', '우리디자인'];
                const SITES_NAMES = ['강남 오피스텔', '판교 IT센터', '분당 아파트', '성수동 카페', '홍대 리모델링', '부산 해운대 호텔', '대구 복합단지', '광주 아파트', '대전 연구소', '인천 물류센터'];
                const SITE_LOCATIONS = ['서울 강남구', '경기 성남시', '경기 성남시', '서울 성동구', '서울 마포구', '부산 해운대구', '대구 수성구', '광주 서구', '대전 유성구', '인천 중구'];

                const newSites: any[] = [];
                const existingSitesRaw = localStorage.getItem('employerSites');
                if (existingSitesRaw) {
                    newSites.push(...JSON.parse(existingSitesRaw));
                } else {
                    newSites.push({
                        id: 'site_req_sample_1',
                        ownerId: TEST_EMPLOYER_PHONE,
                        name: '서초 아파트 재건축',
                        address: '서울 서초구 반포동',
                        supervisorName: '박소장',
                        supervisorPhone: TEST_EMPLOYER_PHONE,
                        jobType: '조공',
                        status: 'approved',
                        createdAt: '2024-07-25T10:00:00.000Z'
                    });
                }

                EMPLOYER_NAMES.forEach((name, index) => {
                    const phone = `0109000${String(index).padStart(4, '0')}`;
                    if (!currentEmployers.find((e: any) => e.phone === phone)) {
                        currentEmployers.push({
                            phone,
                            name,
                            companyName: COMPANIES[index],
                            isRegistered: true
                        });
                        newSites.push({
                            id: `site_req_mock_${index}`,
                            ownerId: phone,
                            name: SITES_NAMES[index],
                            address: SITE_LOCATIONS[index],
                            supervisorName: name,
                            supervisorPhone: phone,
                            jobType: '보통인부',
                            status: 'approved',
                            createdAt: `2024-08-0${(index % 9) + 1}T09:${String(index*3).padStart(2,'0')}:00.000Z`
                        });
                    }
                });

                localStorage.setItem('employers', JSON.stringify(currentEmployers));
                localStorage.setItem('employerSites', JSON.stringify(newSites));
            }
        } catch (error) {
            console.error("Failed to seed mock data in Router:", error);
        }
    }, []);

    useEffect(() => {
        if (view !== 'landing') return;
        try {
            const savedAdmins = localStorage.getItem('adminUsers');
            if (savedAdmins) {
                setAdminUsers(JSON.parse(savedAdmins));
            } else {
                setAdminUsers(ADMIN_USERS_DATA);
            }
        } catch (error) {
            console.error("Failed to load admin users in Router:", error);
            setAdminUsers(ADMIN_USERS_DATA);
        }
    }, [view]);

    const roleConfig: Record<Role, { label: string; description: string; testHint: string; activeClass: string }> = {
        user: {
            label: '근로자',
            description: '내 주변 현장을 찾고 간편하게 지원하세요.',
            testHint: '01011112222',
            activeClass: 'bg-slate-900 border-amber-500 text-amber-300'
        },
        employer: {
            label: '구인자',
            description: '현장 등록부터 출석 관리까지 한 번에.',
            testHint: '01099998888',
            activeClass: 'bg-slate-900 border-indigo-500 text-indigo-300'
        }
    };

    const resetAuthFlow = () => {
        setAuthStep('login');
        setPhoneToVerify(null);
        setAuthRole(null);
        setRememberMe(true);
    };

    const handleRoleChange = (role: Role) => {
        setActiveRole(role);
        setAuthStep('login');
        setPhoneToVerify(null);
        setAuthRole(null);
    };

    const handleBackToLanding = () => {
        setView('landing');
        resetAuthFlow();
        setIsAdminPanelOpen(false);
    };

    const persistSessionValue = (key: string, value: unknown, remember: boolean) => {
        const serialized = JSON.stringify(value);
        if (remember) {
            localStorage.setItem(key, serialized);
            sessionStorage.removeItem(key);
        } else {
            sessionStorage.setItem(key, serialized);
            localStorage.removeItem(key);
        }
    };

    const handlePhoneLogin = (phone: string, remember: boolean) => {
        setRememberMe(remember);
        setPhoneToVerify(phone);
        setAuthRole(activeRole);
        setAuthStep('verify');
    };

    const handlePhoneAuthSuccess = (remember: boolean) => {
        if (!phoneToVerify || !authRole) return;

        if (authRole === 'user') {
            let registeredUsers: StoredUser[] = [];
            try {
                const registeredUsersRaw = localStorage.getItem('registeredUsers');
                registeredUsers = registeredUsersRaw ? JSON.parse(registeredUsersRaw) : [];
            } catch (error) {
                console.error("Failed to parse registeredUsers:", error);
            }
            const existingUser = registeredUsers.find(u => u.phone === phoneToVerify);
            const user = {
                phone: phoneToVerify,
                name: existingUser ? existingUser.name : null,
                isRegistered: Boolean(existingUser)
            };
            persistSessionValue('currentUser', user, remember);
            setView('user');
        } else if (authRole === 'employer') {
            let employers: StoredEmployer[] = [];
            try {
                const employersRaw = localStorage.getItem('employers');
                employers = employersRaw ? JSON.parse(employersRaw) : [];
            } catch (error) {
                console.error("Failed to parse employers:", error);
            }
            const existingEmployer = employers.find(e => e.phone === phoneToVerify);
            const employer = existingEmployer || {
                phone: phoneToVerify,
                name: '',
                companyName: '',
                isRegistered: false
            };
            persistSessionValue('currentEmployer', employer, remember);
            setView('employer');
        }

        resetAuthFlow();
    };

    const handleAdminLogin = (user: AdminUser) => {
        localStorage.setItem('currentAdmin', JSON.stringify(user));
        setView('admin');
        resetAuthFlow();
        setIsAdminPanelOpen(false);
    };

    if (view === 'user') {
        return (
            <div className="relative">
                <UserApp onLogout={handleBackToLanding} />
                <button 
                    onClick={handleBackToLanding}
                    className="fixed bottom-4 right-4 z-50 bg-slate-800 text-slate-400 px-3 py-1 rounded-full text-xs opacity-50 hover:opacity-100 transition border border-slate-700"
                >
                    모드 변경
                </button>
            </div>
        );
    }

    if (view === 'employer') {
        return (
            <div className="relative">
                <EmployerApp onLogout={handleBackToLanding} />
                <button 
                    onClick={handleBackToLanding}
                    className="fixed bottom-4 right-4 z-50 bg-slate-800 text-slate-400 px-3 py-1 rounded-full text-xs opacity-50 hover:opacity-100 transition border border-slate-700"
                >
                    모드 변경
                </button>
            </div>
        );
    }

    if (view === 'admin') {
        return (
            <div className="relative">
                <AdminApp onLogout={handleBackToLanding} />
                <button 
                    onClick={handleBackToLanding}
                    className="fixed bottom-4 right-4 z-50 bg-slate-800 text-slate-400 px-3 py-1 rounded-full text-xs opacity-50 hover:opacity-100 transition border border-slate-700"
                >
                    모드 변경
                </button>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-slate-900 text-slate-300 flex items-center justify-center p-4 font-sans">
            <div className="max-w-5xl w-full animate-fadeIn">
                <div className="text-center mb-10">
                    <div className="inline-flex items-center justify-center p-4 bg-gradient-to-tr from-amber-500 to-orange-600 rounded-2xl shadow-lg mb-6">
                        <svg xmlns="http://www.w3.org/2000/svg" className="h-12 w-12 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5h1.586a1 1 0 01.707.293l2.414 2.414a1 1 0 00.707.293h3.172a1 1 0 00.707-.293l2.414-2.414a1 1 0 01.707-.293H21" />
                        </svg>
                    </div>
                    <h1 className="text-3xl md:text-5xl font-bold text-white mb-4 tracking-tight">건설 인력 매칭 플랫폼</h1>
                    <p className="text-lg text-slate-400 max-w-2xl mx-auto">
                        현장과 인력을 잇는 스마트한 솔루션. <br className="hidden md:block"/>
                        채용부터 급여 정산까지, 하나의 플랫폼에서 관리하세요.
                    </p>
                </div>

                <div className="max-w-xl mx-auto">
                    <div className="grid grid-cols-2 gap-2 bg-slate-800/60 p-2 rounded-2xl border border-slate-700">
                        {(Object.keys(roleConfig) as Role[]).map((role) => (
                            <button
                                key={role}
                                onClick={() => handleRoleChange(role)}
                                className={`px-3 py-2 rounded-xl border text-sm font-semibold transition ${
                                    activeRole === role
                                        ? roleConfig[role].activeClass
                                        : 'border-transparent text-slate-400 hover:text-slate-200 hover:bg-slate-800/70'
                                }`}
                            >
                                {roleConfig[role].label}
                            </button>
                        ))}
                    </div>

                    <p className="mt-4 text-center text-sm text-slate-400">
                        {roleConfig[activeRole].description}
                    </p>

                    <div className="mt-6">
                        {authStep === 'verify' ? (
                            <Authentication
                                phone={phoneToVerify!}
                                onVerify={handlePhoneAuthSuccess}
                                onBack={resetAuthFlow}
                                rememberMe={rememberMe}
                            />
                        ) : (
                            <Login onLogin={handlePhoneLogin} />
                        )}
                    </div>

                    <p className="mt-4 text-center text-xs text-slate-500">
                        테스트 계정: {roleConfig[activeRole].testHint}
                    </p>
                </div>

                <footer className="mt-12 text-center text-slate-500 text-xs">
                    <p>© 2024 Construction Workforce Matching Platform. All rights reserved.</p>
                </footer>
            </div>
            {isAdminPanelOpen ? (
                <div className="fixed bottom-4 right-4 w-[90vw] max-w-sm z-50">
                    <div className="relative">
                        <button
                            type="button"
                            onClick={() => setIsAdminPanelOpen(false)}
                            className="absolute -top-3 -right-3 h-8 w-8 rounded-full bg-slate-800 border border-slate-600 text-slate-200 text-sm hover:bg-slate-700 transition"
                            aria-label="관리자 로그인 닫기"
                        >
                            ×
                        </button>
                        <AdminLogin variant="panel" users={adminUsers} onLogin={handleAdminLogin} />
                        <p className="mt-3 text-center text-xs text-slate-400">테스트 계정: master / 1</p>
                    </div>
                </div>
            ) : (
                <button
                    type="button"
                    onClick={() => setIsAdminPanelOpen(true)}
                    className="fixed bottom-4 right-4 z-40 bg-slate-800 text-slate-200 px-4 py-2 rounded-full text-sm font-semibold border border-slate-600 hover:bg-slate-700 transition"
                >
                    관리자 로그인
                </button>
            )}
        </div>
    );
};

export default Router;
