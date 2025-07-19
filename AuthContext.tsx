import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface User {
  token: string;
  role: string;
}

interface AuthContextType {
  user: User | null;
  login: (token: string, role?: string) => void;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider = ({ children }: AuthProviderProps) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const initializeAuth = () => {
      try {
        const token = localStorage.getItem('token');
        const userRole = localStorage.getItem('userRole');
        
        if (token) {
          const role = userRole || 'influencer'; // Default to influencer if no role found
          const newUser: User = { token, role };
          setUser(newUser);
        }
      } catch (error) {
        console.error('Error initializing auth:', error);
        // Clear potentially corrupted data
        localStorage.removeItem('token');
        localStorage.removeItem('userRole');
      } finally {
        setIsLoading(false);
      }
    };

    initializeAuth();
  }, []);

  const login = (token: string, role: string = 'influencer') => {
    try {
      localStorage.setItem('token', token);
      localStorage.setItem('userRole', role);
      const newUser: User = { token, role };
      setUser(newUser);
    } catch (error) {
      console.error('Error during login:', error);
    }
  };

  const logout = () => {
    try {
      localStorage.removeItem('token');
      localStorage.removeItem('userRole');
      setUser(null);
    } catch (error) {
      console.error('Error during logout:', error);
    }
  };

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <AuthContext.Provider value={{ user, login, logout, isLoading }}>
      {children}
    </AuthContext.Provider>
  );
};

// Custom hook with proper error handling
export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  
  return context;
};

// Optional: Hook that returns null instead of throwing error
export const useAuthSafe = (): AuthContextType | null => {
  return useContext(AuthContext);
};