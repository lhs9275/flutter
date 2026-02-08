야 그import React, { useState, useEffect } from 'react';
import { Header } from './components/Header';
import { Footer } from './components/Footer';
import { Login } from './components/Login';
import { Authentication } from './components/Authentication';
import { RegistrationForm, SubmissionData } from './components/KeywordInput';
import { EditProfileForm, ProfileUpdateData } from './components/EditProfileForm';
import { ReportDisplay } from './components/ReportDisplay';
import { SiteList } from './components/SiteList';
import { SiteDetail } from './components/SiteDetail';
import { CalendarView } from './components/CalendarView';
import { HistoryDetailView } from './components/HistoryDetailView';
import { UserInfoView, UserProfile } from './components/UserInfoView';
import { SITES_DATA, Site } from './data/sites';
import { WORK_HISTORY_DATA, WorkHistory } from './data/workHistory';

type View = 'login' | 'authenticate' | 'register' | 'register-success' | 'sites' | 'site-detail' | 'edit-profile';
type SiteViewTab = 'list' | 'calendar' | 'history' | 'userInfo';

interface StoredUser {
  phone: string;
  name: string;
}

const App: React.FC = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentUser, setCurrentUser] = useState<{ phone: string; name: string | null; isRegistered?: boolean } | null>(null);
  const [currentView, setCurrentView] = useState<View>('login');
  const [submission, setSubmission] = useState<SubmissionData | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [selectedSite, setSelectedSite] = useState<Site | null>(null);
  const [appliedSiteId, setAppliedSiteId] = useState<string | null>(null);
  const [siteViewTab, setSiteViewTab] = useState<SiteViewTab>('list');
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const [userWorkHistory, setUserWorkHistory] = useState<WorkHistory[]>([]);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [phoneToVerify, setPhoneToVerify] = useState<string | null>(null);
  const [shouldRememberUser, setShouldRememberUser] = useState(true);
  const TEST_USER_PHONE = '01011112222';

  useEffect(() => {
    try {
      // Initialize test user and profile if not present
      const registeredUsersRaw = localStorage.getItem('registeredUsers');
      if (!registeredUsersRaw) {
        const initialUsers = [{ phone: TEST_USER_PHONE, name: '김테스트' }];
        localStorage.setItem('registeredUsers', JSON.stringify(initialUsers));
      }
      
      const userProfilesRaw = localStorage.getItem('userProfiles');
      let profiles = userProfilesRaw ? JSON.parse(userProfilesRaw) : {};
      if (!profiles[TEST_USER_PHONE]) {
          profiles[TEST_USER_PHONE] = {
              name: '김테스트',
              rrn: '850101-1******',
              gender: 'male',
              nationality: 'korean',
              phone: TEST_USER_PHONE,
              preferredAreas: ['서울 강남구', '경기 성남시 분당구'],
              bank: 'KB국민은행',
              accountNumber: '123-456-789012',
              accountHolder: '김테스트',
              signatureDataUrl: '',
              bankAccountFileName: '통장사본.jpg',
              idCardFileName: '신분증.jpg',
              safetyCertFileName: '이수증.jpg',
              profilePictureFileName: '프로필사진.jpg',
          };
          localStorage.setItem('userProfiles', JSON.stringify(profiles));
      }
      
      const savedUser = localStorage.getItem('currentUser');
      if (savedUser) {
        const user = JSON.parse(savedUser);
        setIsAuthenticated(true);
        setCurrentUser(user);
        setCurrentView(user.isRegistered ? 'sites' : 'register');
        setUserWorkHistory(WORK_HISTORY_DATA.filter(wh => wh.userId === user.phone));

        const savedProfiles = localStorage.getItem('userProfiles');
        if (savedProfiles) {
            const profiles = JSON.parse(savedProfiles);
            setUserProfile(profiles[user.phone] || null);
        }
      }
      const savedAppliedSiteId = localStorage.getItem('appliedSiteId');
      if (savedAppliedSiteId) {
        setAppliedSiteId(savedAppliedSiteId);
      }
    } catch (error) {
      console.error("Failed to parse data from localStorage", error);
      localStorage.clear(); // Clear local storage on parsing error
    }
  }, []);

  const handleLogin = (phone: string, rememberMe: boolean) => {
    setShouldRememberUser(rememberMe);
    setPhoneToVerify(phone);
    setCurrentView('authenticate');
  };
  
  const handleAuthSuccess = (rememberMe: boolean) => {
    if (!phoneToVerify) return;

    const registeredUsersRaw = localStorage.getItem('registeredUsers');
    const registeredUsers: StoredUser[] = registeredUsersRaw ? JSON.parse(registeredUsersRaw) : [];
    const existingUser = registeredUsers.find(u => u.phone === phoneToVerify);
    
    let user: { phone: string; name: string | null; isRegistered: boolean; };

    if (existingUser) {
        user = { phone: phoneToVerify, name: existingUser.name, isRegistered: true };
        setCurrentUser(user);
        setUserWorkHistory(WORK_HISTORY_DATA.filter(wh => wh.userId === phoneToVerify));
        
        const userProfilesRaw = localStorage.getItem('userProfiles');
        if (userProfilesRaw) {
            const profiles = JSON.parse(userProfilesRaw);
            setUserProfile(profiles[phoneToVerify] || null);
        }
        setCurrentView('sites');
    } else {
        user = { phone: phoneToVerify, name: null, isRegistered: false };
        setCurrentUser(user);
        setCurrentView('register');
    }
    
    setIsAuthenticated(true);

    if (rememberMe) {
      localStorage.setItem('currentUser', JSON.stringify(user));
    }
    
    setPhoneToVerify(null);
  };
  
  const handleBackToLogin = () => {
    setPhoneToVerify(null);
    setCurrentView('login');
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    setCurrentUser(null);
    setCurrentView('login');
    setPhoneToVerify(null);
    localStorage.removeItem('currentUser');
    setUserWorkHistory([]);
    setUserProfile(null);
  };

  const handleRegistrationSubmit = (data: SubmissionData) => {
    if (!currentUser) return;
    setIsLoading(true);
    console.log('Registration Data Submitted:', data);
    
    setTimeout(() => {
        setSubmission(data);
        const updatedUser = { ...currentUser, name: data.name, isRegistered: true };
        setCurrentUser(updatedUser);

        const registeredUsersRaw = localStorage.getItem('registeredUsers');
        const registeredUsers: StoredUser[] = registeredUsersRaw ? JSON.parse(registeredUsersRaw) : [];
        const newUser: StoredUser = { phone: currentUser.phone, name: data.name };
        if (!registeredUsers.find(u => u.phone === newUser.phone)) {
            registeredUsers.push(newUser);
        }
        localStorage.setItem('registeredUsers', JSON.stringify(registeredUsers));

        const userProfileData: UserProfile = {
            ...data,
            bankAccountFileName: data.bankAccountFile.name,
            idCardFileName: data.idCardFile.name,
            safetyCertFileName: data.safetyCertFile.name,
        };
        if (data.profilePictureFile) {
            userProfileData.profilePictureFileName = data.profilePictureFile.name;
        }

        const profilesRaw = localStorage.getItem('userProfiles');
        const profiles = profilesRaw ? JSON.parse(profilesRaw) : {};
        profiles[currentUser.phone] = userProfileData;
        localStorage.setItem('userProfiles', JSON.stringify(profiles));
        setUserProfile(userProfileData);
        
        if (shouldRememberUser || localStorage.getItem('currentUser')) {
          localStorage.setItem('currentUser', JSON.stringify(updatedUser));
        }

        setIsLoading(false);
        setCurrentView('register-success');
    }, 2000);
  };

  const handleProceedToSites = () => {
    setCurrentView('sites');
  };

  const handleSelectSite = (site: Site) => {
    setSelectedSite(site);
    setCurrentView('site-detail');
  };

  const handleBackToList = () => {
    setSelectedSite(null);
    setCurrentView('sites');
    setSiteViewTab('list');
  };
  
  const handleApplyForSite = (siteId: string) => {
    setAppliedSiteId(siteId);
    localStorage.setItem('appliedSiteId', siteId);
  };

  const handleNavigateToHistory = (date: string) => {
    setSelectedDate(date);
    setSiteViewTab('history');
  };

  const handleNavigateToEditProfile = () => {
    setCurrentView('edit-profile');
  };

  const handleBackToUserInfo = () => {
    setCurrentView('sites');
    setSiteViewTab('userInfo');
  };

  const handleProfileUpdate = (data: ProfileUpdateData) => {
    if (!currentUser || !userProfile) return;
    
    setIsLoading(true);
    
    setTimeout(() => {
        const updatedProfile: UserProfile = { ...userProfile };
        
        Object.assign(updatedProfile, {
            name: data.name,
            gender: data.gender,
            nationality: data.nationality,
            country: data.country,
            countryOther: data.countryOther,
            visaType: data.visaType,
            visaTypeOther: data.visaTypeOther,
            preferredAreas: data.preferredAreas,
            bank: data.bank,
            accountNumber: data.accountNumber,
            accountHolder: data.accountHolder,
        });

        if (data.profilePictureFile) updatedProfile.profilePictureFileName = data.profilePictureFile.name;
        if (data.idCardFile) updatedProfile.idCardFileName = data.idCardFile.name;
        if (data.safetyCertFile) updatedProfile.safetyCertFileName = data.safetyCertFile.name;
        if (data.bankAccountFile) updatedProfile.bankAccountFileName = data.bankAccountFile.name;
        
        const profilesRaw = localStorage.getItem('userProfiles');
        const profiles = profilesRaw ? JSON.parse(profilesRaw) : {};
        profiles[currentUser.phone] = updatedProfile;
        localStorage.setItem('userProfiles', JSON.stringify(profiles));
        setUserProfile(updatedProfile);

        if (updatedProfile.name !== currentUser.name) {
            const updatedCurrentUser = { ...currentUser, name: updatedProfile.name, isRegistered: true };
            setCurrentUser(updatedCurrentUser);
            if (localStorage.getItem('currentUser')) {
                localStorage.setItem('currentUser', JSON.stringify(updatedCurrentUser));
            }
        }
        
        setIsLoading(false);
        handleBackToUserInfo();
    }, 1500);
  };

  const TabButton: React.FC<{ active: boolean; onClick: () => void; children: React.ReactNode }> = ({ active, onClick, children }) => {
    return (
      <button
        onClick={onClick}
        className={`px-4 py-3 text-sm font-semibold transition-colors duration-200 w-full text-center
          ${active 
            ? 'border-b-2 border-amber-500 text-amber-400' 
            : 'border-b-2 border-transparent text-slate-400 hover:text-slate-200'
          }`}
      >
        {children}
      </button>
    );
  };

  const renderContent = () => {
    if (currentView === 'authenticate') {
      return <Authentication phone={phoneToVerify!} onVerify={handleAuthSuccess} onBack={handleBackToLogin} rememberMe={shouldRememberUser} />;
    }
    
    if (!isAuthenticated || currentView === 'login') {
      return <Login onLogin={handleLogin} />;
    }

    switch (currentView) {
      case 'register':
        return <RegistrationForm onSubmit={handleRegistrationSubmit} isLoading={isLoading} currentUserPhone={currentUser!.phone}/>;
      case 'register-success':
        return <ReportDisplay submission={submission} isLoading={isLoading} onProceed={handleProceedToSites}/>;
      case 'edit-profile':
          return userProfile ? (
            <EditProfileForm 
                initialProfile={userProfile} 
                onSubmit={handleProfileUpdate} 
                onCancel={handleBackToUserInfo}
                isLoading={isLoading} 
            />
          ) : ( <div>사용자 프로필을 로드할 수 없습니다.</div> );
      case 'sites':
        return (
          <div className="animate-fadeIn">
            <div className="mb-6 flex border-b border-slate-700 bg-slate-800/50 rounded-t-lg">
              <TabButton active={siteViewTab === 'list'} onClick={() => setSiteViewTab('list')}>모집중인 현장</TabButton>
              <TabButton active={siteViewTab === 'calendar'} onClick={() => setSiteViewTab('calendar')}>출역 달력</TabButton>
              <TabButton active={siteViewTab === 'history'} onClick={() => { setSelectedDate(null); setSiteViewTab('history'); }}>상세 내역</TabButton>
              <TabButton active={siteViewTab === 'userInfo'} onClick={() => setSiteViewTab('userInfo')}>회원정보</TabButton>
            </div>
            <div className="animate-fadeIn">
              {siteViewTab === 'list' && <SiteList sites={SITES_DATA} onSelectSite={handleSelectSite} appliedSiteId={appliedSiteId} />}
              {siteViewTab === 'calendar' && <CalendarView workHistory={userWorkHistory} onDayClick={handleNavigateToHistory} />}
              {siteViewTab === 'history' && <HistoryDetailView workHistory={userWorkHistory} selectedDate={selectedDate} />}
              {siteViewTab === 'userInfo' && <UserInfoView userProfile={userProfile} onEdit={handleNavigateToEditProfile}/>}
            </div>
          </div>
        );
      case 'site-detail':
        return selectedSite ? 
            <SiteDetail site={selectedSite} onBack={handleBackToList} appliedSiteId={appliedSiteId} onApply={handleApplyForSite} currentUser={currentUser}/> 
            : <SiteList sites={SITES_DATA} onSelectSite={handleSelectSite} appliedSiteId={appliedSiteId} />;
      default:
        return <Login onLogin={handleLogin} />;
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-300 flex flex-col font-sans">
      <Header isAuthenticated={isAuthenticated} currentUser={currentUser} onLogout={handleLogout}/>
      <main className="container mx-auto px-4 py-8 flex-grow">
        <div className="max-w-4xl mx-auto">
          {renderContent()}
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default App;
