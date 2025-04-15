# Clear existing navigation items
NavigationItem.destroy_all

# Create main navigation items
home = NavigationItem.create!(
  title: 'Home',
  path: '/',
  icon: 'home',
  position: 1
)

services = NavigationItem.create!(
  title: 'Services',
  path: '/services',
  icon: 'services',
  position: 2
)

community = NavigationItem.create!(
  title: 'Community',
  path: '/community',
  icon: 'users',
  position: 3
)

marketplace = NavigationItem.create!(
  title: 'Marketplace',
  path: '/marketplace',
  icon: 'shopping-cart',
  position: 4,
  required_role: 1 # Requires standard user role
)

account = NavigationItem.create!(
  title: 'My Account',
  path: '/account',
  icon: 'user',
  position: 5,
  required_role: 1 # Requires standard user role
)

admin = NavigationItem.create!(
  title: 'Admin',
  path: '/admin',
  icon: 'shield',
  position: 6,
  required_role: 3 # Requires admin role
)

# Create child items for Services
NavigationItem.create!(
  title: 'Send Money',
  path: '/services/send-money',
  icon: 'money',
  position: 1,
  parent: services
)

NavigationItem.create!(
  title: 'Bill Payments',
  path: '/services/bill-payments',
  icon: 'file-invoice',
  position: 2,
  parent: services
)

NavigationItem.create!(
  title: 'Loans',
  path: '/services/loans',
  icon: 'credit-card',
  position: 3,
  parent: services,
  required_role: 2 # Requires verified user role
)

# Create child items for Community
NavigationItem.create!(
  title: 'Groups',
  path: '/community/groups',
  icon: 'users-group',
  position: 1,
  parent: community
)

NavigationItem.create!(
  title: 'Events',
  path: '/community/events',
  icon: 'calendar',
  position: 2,
  parent: community
)

NavigationItem.create!(
  title: 'Forums',
  path: '/community/forums',
  icon: 'comments',
  position: 3,
  parent: community
)

# Create child items for My Account
NavigationItem.create!(
  title: 'Profile',
  path: '/account/profile',
  icon: 'user-circle',
  position: 1,
  parent: account,
  required_role: 1 # Requires standard user role
)

NavigationItem.create!(
  title: 'Wallet',
  path: '/account/wallet',
  icon: 'wallet',
  position: 2,
  parent: account,
  required_role: 1 # Requires standard user role
)

NavigationItem.create!(
  title: 'Security',
  path: '/account/security',
  icon: 'lock',
  position: 3,
  parent: account,
  required_role: 1 # Requires standard user role
)

# Create child items for Admin
NavigationItem.create!(
  title: 'Dashboard',
  path: '/admin/dashboard',
  icon: 'tachometer',
  position: 1,
  parent: admin,
  required_role: 3 # Requires admin role
)

NavigationItem.create!(
  title: 'Users',
  path: '/admin/users',
  icon: 'user-group',
  position: 2,
  parent: admin,
  required_role: 3 # Requires admin role
)

NavigationItem.create!(
  title: 'Settings',
  path: '/admin/settings',
  icon: 'cog',
  position: 3,
  parent: admin,
  required_role: 3 # Requires admin role
)

puts "Created #{NavigationItem.count} navigation items"
