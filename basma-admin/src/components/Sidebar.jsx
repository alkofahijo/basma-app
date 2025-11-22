// src/components/Sidebar.jsx
import React from 'react';
import { Drawer, List, ListItemButton, ListItemIcon, ListItemText, Toolbar } from '@mui/material';
import PeopleIcon from '@mui/icons-material/People';
import AssignmentIcon from '@mui/icons-material/Assignment';
import BusinessIcon from '@mui/icons-material/Business';
import { useNavigate, useLocation } from 'react-router-dom';

const drawerWidth = 220;

const Sidebar = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const items = [
    { label: 'المستخدمون', icon: <PeopleIcon />, path: '/users' },
    { label: 'البلاغات', icon: <AssignmentIcon />, path: '/reports' },
    { label: 'الحسابات', icon: <BusinessIcon />, path: '/accounts' },
  ];

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: drawerWidth,
          boxSizing: 'border-box',
        },
      }}
      anchor="right" // RTL
    >
      <Toolbar />
      <List>
        {items.map((item) => (
          <ListItemButton
            key={item.path}
            selected={location.pathname === item.path}
            onClick={() => navigate(item.path)}
          >
            <ListItemIcon>{item.icon}</ListItemIcon>
            <ListItemText primary={item.label} />
          </ListItemButton>
        ))}
      </List>
    </Drawer>
  );
};

export default Sidebar;
